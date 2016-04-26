#========================================================================================
# §package      DE_INNOCHANGE::Wirecard::API::Payment
# §state        public
#----------------------------------------------------------------------------------------
# §description  helper functions for Wirecard payment
#
# Shop System Plugins - Terms of use
# This terms of use regulates warranty and liability between Wirecard Central Eastern Europe
# (subsequently referred to as WDCEE) and it's contractual partners (subsequently referred
# to as customer or customers) which are related to the use of plugins provided by WDCEE.
# The Plugin is provided by WDCEE free of charge for it's customers and must be used for
# the purpose of WDCEE's payment platform integration only. It explicitly is not part of
# the general contract between WDCEE and it's customer. The plugin has successfully been
# tested under specific circumstances which are defined as the shopsystem's standard
# configuration (vendor's delivery state). The Customer is responsible for testing the
# plugin's functionality before putting it into production enviroment. The customer uses the
# plugin at own risk. WDCEE does not guarantee it's full functionality neither does WDCEE
# assume liability for any disadvantage related to the use of this plugin. By installing the
# plugin into the shopsystem the customer agrees to the terms of use. Please do not use this
# plugin if you do not agree to the terms of use!
#========================================================================================
package DE_INNOCHANGE::Wirecard::API::Payment;
use base qw( Exporter );

use strict;
our @EXPORT_OK = qw (
  CalculateFingerprint
  InitTransaction
);

use Net::INET6Glue;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Request::Common qw (POST);
use Digest::MD5 qw (md5_hex);
use MIME::Base64 qw (encode_base64);
use Encode qw (encode);

use DE_EPAGES::Core::API::Error     qw (Error);
use DE_EPAGES::Core::API::Url qw (ParseQueryString);
use DE_EPAGES::ExternalPayment::API::Log qw (LogPayment);
use DE_EPAGES::Object::API::Factory qw (LoadRootObject);
use DE_EPAGES::Object::API::Language qw (GetCodeByLanguageID);
use DE_EPAGES::Presentation::API::Template qw (Translate);
use DE_EPAGES::Shop::API::Url qw (BuildShopUrl);

#========================================================================================
# §function     InitTransaction
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $redirectUrl = InitTransaction($Container, $RemoteAddr, $UserAgent, $IsMobile);
#----------------------------------------------------------------------------------------
# §description  Inititate payment transaction. If successful, the redirect url received from
#               Wirecard is returned. If not successful, returns undef.
#----------------------------------------------------------------------------------------
# §input        $Container | line item container | object
# §input        $RemoteAddr | client ip address | string
# §input        $UserAgent | cient user agent string | string
# §input        $IsMobile | client is a mobile device | boolean
# §return       $redirect url | url to redirect customer to, undef on error | string
#========================================================================================
sub InitTransaction {
  my ($Container, $RemoteAddr, $UserAgent, $IsMobile) = @_;

  my $pli = $Container->get('Payment');
  Error('NO_WIRECARD', {'ObjectPath' => $pli->pathString}) unless($pli->instanceOf('LineItemPaymentICWirecard'));

  my $PaymentMethod = $pli->get('PaymentMethod');
  Error('NO_WIRECARD', {'ObjectPath' => $pli->pathString}) unless(defined($PaymentMethod) && $PaymentMethod->instanceOf('PaymentMethodICWirecard'));

  my $Shop = $Container->getSite;
  my $LanguageID = $Container->get('LanguageID');
  my %Params = (
    'customerId'              => $PaymentMethod->get('customerId'),
    'language'                => GetCodeByLanguageID($LanguageID),
    'paymentType'             => $PaymentMethod->get('paymentType'),
    'amount'                  => $pli->get('Amount'),
    'currency'                => $pli->get('CurrencyID'),
    'orderDescription'        => Translate('ICYourOrderAt', $LanguageID, 'DE_INNOCHANGE::Wirecard') . ' ' . $Shop->get('NameOrAlias', $LanguageID),
    'successUrl'              => BuildShopUrl($Shop, {'ChangeAction' => 'PaymentSuccessICWirecard'}, {'UseSSL' => 1, 'UseObjectPath' => 1, 'Type' => 'sf/mobile'}),
    'failureUrl'              => BuildShopUrl($Shop, {'ChangeAction' => 'PaymentFailureICWirecard'}, {'UseSSL' => 1, 'UseObjectPath' => 1, 'Type' => 'sf/mobile'}),
    'confirmUrl'              => BuildShopUrl($Shop, {'ChangeAction' => 'PaymentConfirmICWirecard', 'ViewAction' => 'SendPaymentConfirmICWirecardResponse'}, {'UseSSL' => 1, 'UseObjectPath' => 1, 'Type' => 'sf/mobile'}),
    'cancelUrl'               => BuildShopUrl($Container->parent, {}, {'UseSSL' => 1, 'UseObjectPath' => 0, 'Type' => 'sf/mobile'}), # back to basket page
    'consumerUserAgent'       => $UserAgent,
    'consumerIpAddress'       => $RemoteAddr,
    'orderReference'          => $Container->parent->id,
    'layout'                  => $IsMobile ? 'smartphone' : 'desktop',
    'maxRetries'              => 2,
    'ic_paymentGUID'          => $pli->get('GUID'),
    'pluginVersion'           => _getPluginVersion()
  );

  # service url
  my $CustomerInfo = $Shop->get('CustomerInformation');
  if (defined($CustomerInfo) && $CustomerInfo->get('IsVisible')) { # url to customer info page if it exists and is visible
    $Params{'serviceUrl'} = $CustomerInfo->get('WebUrlSSL');
  }
  else { # shop start page otherwise
    $Params{'serviceUrl'} = $Shop->get('WebUrlSSL');
  }

  # authorize / capture
  $Params{'autoDeposit'} = 'yes' unless ($PaymentMethod->get('TransactionType'));

  # shopId
  my $shopId = $PaymentMethod->get('shopId');
  $Params{'shopId'} = $shopId if (defined $shopId);

  # image url (shop logo)
  my $logoUrl = _getShopLogoUrl($Shop);
  $Params{'imageUrl'} = $logoUrl if (defined $logoUrl);

  # add address data if configured
  if ($PaymentMethod->get('sendAddressData')) {
    my $BillingAddress = $Container->parent->get('BillingAddress');
    my $Country = $BillingAddress->get('Country');
    my $BirthDate = $BillingAddress->get('Birthday');
    $Params{'consumerBillingFirstname'} = $BillingAddress->get('FirstName');
    $Params{'consumerBillingLastname'}  = $BillingAddress->get('LastName');
    $Params{'consumerBillingAddress1'}  = $BillingAddress->get('Street');
    $Params{'consumerBillingAddress2'}  = '';
    $Params{'consumerBillingCity'}      = $BillingAddress->get('City');
    $Params{'consumerBillingCountry'}   = defined($Country)  ?  $Country->{'Code2'} : undef;
    $Params{'consumerBillingZipCode'}   = $BillingAddress->get('Zipcode');
    $Params{'consumerEmail'}            = $BillingAddress->get('EMail');
    $Params{'consumerBirthDate'}        = defined($BirthDate)  ?  $BirthDate->strftime('%Y-%m-%d') : undef;
    $Params{'consumerBillingPhone'}     = $BillingAddress->get('Phone');
    $Params{'consumerBillingFax'}       = $BillingAddress->get('Fax');

    my $ShippingAddress = $Container->parent->get('ShippingAddress') // $BillingAddress;
    $Country = $ShippingAddress->get('Country');
    my $State = $ShippingAddress->get('State');
    $State = substr($State, 0, 2) if (defined($State) && length($State) > 2);
    $Params{'consumerShippingFirstname'} = $ShippingAddress->get('FirstName');
    $Params{'consumerShippingLastname'}  = $ShippingAddress->get('LastName');
    $Params{'consumerShippingAddress1'}  = $ShippingAddress->get('Street');
    $Params{'consumerShippingAddress2'}  = '';
    $Params{'consumerShippingCity'}      = $ShippingAddress->get('City');
    $Params{'consumerShippingState'}     = $State;
    $Params{'consumerShippingCountry'}   = defined($Country)  ?  $Country->{'Code2'} : undef;
    $Params{'consumerShippingZipCode'}   = $ShippingAddress->get('Zipcode');
    $Params{'consumerEmail'}             = $ShippingAddress->get('EMail');
    $Params{'consumerShippingPhone'}     = $ShippingAddress->get('Phone');
    $Params{'consumerShippingFax'}       = $ShippingAddress->get('Fax');
  }

  # calculate finger print
  my @RequestFingerprintItems = keys %Params;
  unshift(@RequestFingerprintItems, 'secret');
  push(@RequestFingerprintItems, 'requestFingerprintOrder');
  $Params{'requestFingerprintOrder'} = join(',', @RequestFingerprintItems);
  $Params{'requestFingerprint'} = CalculateFingerprint($PaymentMethod->get('secret'), $Params{'requestFingerprintOrder'}, \%Params);
  LogPayment('ICWirecard', sprintf('request params for container %d (%s)', $Container->id, $Container->pathString), \%Params);

  # send request
  my $Request = POST(LoadRootObject()->get('ICWirecard_InitTransactionURL'), \%Params);
  LogPayment('ICWirecard', sprintf('init transaction request for container %d (%s)', $Container->id, $Container->pathString), $Request->as_string);

  my $ua = LWP::UserAgent->new;
  my $Response = $ua->request($Request);
  LogPayment('ICWirecard', sprintf('init transaction response for container %d (%s)', $Container->id, $Container->pathString), $Response->as_string);

  # handle result
  if ($Response->content =~ /^redirectUrl=/) {
    my $hParams = ParseQueryString($Response->content, 'iso-8859-1');
    my $redirectUrl = $hParams->{'redirectUrl'}->[0];
    LogPayment('ICWirecard', sprintf('init transaction request successful for container %d (%s), redirectUrl=', $Container->id, $Container->pathString), $redirectUrl);
    return $redirectUrl;
  }
  LogPayment('ICWirecard', sprintf('init transaction request failed for container %d (%s)', $Container->id, $Container->pathString), '');
  return undef;
}

#========================================================================================
# §function     CalculateFingerprint
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $fingerprint = CalculateFingerprint($secret, $fingerPrintOrder, $hData);
#----------------------------------------------------------------------------------------
# §description  calculate an md5 fingerprint
#----------------------------------------------------------------------------------------
# §input        $secret | payment method's secret | string
# §input        $fingerPrintOrder | comma separated list of hash keys (and secret) specifing the order of values to use for hash calculation | string
# §input        $hData | data hash | ref.hash
# §return       $redirect url | url to redirect customer to, undef on error | string
#========================================================================================
sub CalculateFingerprint {
  my ($secret, $fingerPrintOrder, $hData) = @_;

  my $hashInput = '';
  foreach my $key (split(/,/, $fingerPrintOrder)) {
    $hashInput .= $key eq 'secret'  ?  $secret : encode('utf-8', $hData->{$key} // '');
  }
  return md5_hex($hashInput);
}

#========================================================================================
# §function     _getShopLogoUrl
# §state        private
#----------------------------------------------------------------------------------------
# §syntax       $logUrl = _getShopLogoUrl($Shop);
#----------------------------------------------------------------------------------------
# §description  get url of shop logo
#----------------------------------------------------------------------------------------
# §input        $Shop | shop | object
# §return       $logourl | url of shop logo, undef if no logo exists | string
#========================================================================================
sub _getShopLogoUrl {
  my ($Shop) = @_;

  my $logoUrl;
  my $DefaultStyle = $Shop->get('DefaultStyle');
  if (defined $DefaultStyle) { # first choice: logo of shop default style
    my $logo = $DefaultStyle->get('Logo');
    $logoUrl = $DefaultStyle->get('WebPath') . '/' . $logo if (defined($logo));
  }
  if (!defined($logoUrl)) { # second choice: logo of shop
    my $logo = $Shop->get('Logo');
    $logoUrl = $Shop->get('WebPath') . '/' . $logo if (defined($logo));
  }
  return undef unless defined $logoUrl;

  # add protocol and domain name
  return $Shop->get('ProtocolAndServerSSL') . $logoUrl;
}

#========================================================================================
# §function     _getPluginVersion
# §state        private
#----------------------------------------------------------------------------------------
# §syntax       $pluginVersion = _getPluginVersion();
#----------------------------------------------------------------------------------------
# §description  base 64 encoded string containing data about the client
#----------------------------------------------------------------------------------------
# §return       $pluginVersion | base 64 encoded | string
#========================================================================================
sub _getPluginVersion {

  my $pluginVersion = join(';',
    'epages',                                 # name of shop system
    LoadRootObject()->get('EpagesVersion'),   # version of shop system
    '',                                       # dependecies
    'epages_wcp',                             # plugin name
    '2.0.1'                                   # plugin version
  );
  return encode_base64($pluginVersion, '');
}