#========================================================================================
# §package      DE_INNOCHANGE::Wirecard::API::Object::PaymentMethodICWirecard
# §base         DE_EPAGES::Order::API::Object::ContainerPaymentMethod
# §state        public
#----------------------------------------------------------------------------------------
# §description  Object interface for class PaymentMethodICWirecard
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
package DE_INNOCHANGE::Wirecard::API::Object::PaymentMethodICWirecard;
use base DE_EPAGES::Order::API::Object::ContainerPaymentMethod;

use strict;
use DE_EPAGES::Core::API::PerlTools qw (SubtractDuration);
use DE_EPAGES::Database::API::Connection qw (GetCurrentDBHandle);
use DE_INNOCHANGE::Wirecard::API::Constants qw (WC_PAYMENT_TYPE_INVOICE);
use DE_INNOCHANGE::Wirecard::API::Constants qw (WC_PAYMENT_TYPE_INSTALLMENT);

#========================================================================================
# §function     featureName
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $FeatureName = $PaymentMethodICWirecard->featureName;
#----------------------------------------------------------------------------------------
# §description  Returns the feature name 'ICWirecard'.
#----------------------------------------------------------------------------------------
# §return       $FeatureName | feature name (undef means no feature count) | String
#========================================================================================
sub featureName () { return 'ICWirecard'; }

#========================================================================================
# §function     usableAtStorefront
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $Usable = $PaymentMethod->usableAtStorefront($hVars);
#----------------------------------------------------------------------------------------
# §description  check if all attributes are set needed for use in the storefront
#----------------------------------------------------------------------------------------
# §input        $hVars | <ul>
#                   <li>CurrencyID    - alpha currency code (ISO 4217) - char(3)
#                   <li>TaxModel      - gross or net price    - int
#               </ul> | ref.hash
# §return       $Usable | true if payment method is usable in the storefront | boolean
#========================================================================================
sub usableAtStorefront {
  my $self    = shift;
  my ($hVars) = @_;

  return
    defined($self->get('customerId'))   &&
    defined($self->get('secret')) &&
    $self->SUPER::usableAtStorefront($hVars);
}

#========================================================================================
# §function     canAddToBasket
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       if ($PaymentMethod->canAddToBasket(\%Vars)) {...
#----------------------------------------------------------------------------------------
# §description  ensure that Wirecard invoice can be used
#               - with currency id EUR only
#               - if no shipping address is defined
#               - if customer is at least 18 years old
#----------------------------------------------------------------------------------------
# §input        $hVars | hash (CurrencyID, TaxModel, LineItemContainer) | ref.hash
# §return       $canAddToBasket | true if payment method can be added to the basket | boolean
#========================================================================================
sub canAddToBasket {
  my $self = shift;
  my ($hVars) = @_;

  my $paymentType = $self->get('paymentType');
  if (defined($paymentType) && $paymentType eq WC_PAYMENT_TYPE_INVOICE) {
    # check currency
    return 0 unless ($hVars->{'CurrencyID'} eq 'EUR');

    # no shipping address is allowed
    my $Basket = $hVars->{'LineItemContainer'}->parent;
    my $ShippingAddress = $Basket->get('ShippingAddress');
    my $BillingAddress = $Basket->get('BillingAddress');
    return 0 if (defined($ShippingAddress) && defined($BillingAddress) && $ShippingAddress->id != $BillingAddress->id);

    # check age of customer if known
    if (defined $BillingAddress) {
      my $Birthday = $BillingAddress->get('Birthday');
      if (defined $Birthday) {
        my $maxBirthday = GetCurrentDBHandle()->currentDateTime;
        SubtractDuration($maxBirthday, 'years', 18);
        return 0 if ($Birthday > $maxBirthday);
      }
    }
  }
  if (defined($paymentType) && $paymentType eq WC_PAYMENT_TYPE_INSTALLMENT) {
    # check currency
    return 0 unless ($hVars->{'CurrencyID'} eq 'EUR');

    # no shipping address is allowed
    my $Basket = $hVars->{'LineItemContainer'}->parent;
    my $ShippingAddress = $Basket->get('ShippingAddress');
    my $BillingAddress = $Basket->get('BillingAddress');
    return 0 if (defined($ShippingAddress) && defined($BillingAddress) && $ShippingAddress->id != $BillingAddress->id);

    # check age of customer if known
    if (defined $BillingAddress) {
      my $Birthday = $BillingAddress->get('Birthday');
      if (defined $Birthday) {
        my $maxBirthday = GetCurrentDBHandle()->currentDateTime;
        SubtractDuration($maxBirthday, 'years', 18);
        return 0 if ($Birthday > $maxBirthday);
      }
    }
  }
  return $self->SUPER::canAddToBasket($hVars);
}

#========================================================================================
# §function     default
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $hValues = DE_INNOCHANGE::Wirecard::API::Object::PaymentMethodICWirecard->default( $Parent, $hInfo );
# §example      $hDefaults = $Class->defaultAttributes($Parent, $hInfo); # for insert a new object
#               $hDefaults = $Object->class->defaultAttributes($Object->parent, $hValues); # for an existing object
#----------------------------------------------------------------------------------------
# §description  Returns default attribute values for new objects.
#               Used by <function DE_EPAGES::Object::Object::Class::defaultAttributes>
#----------------------------------------------------------------------------------------
# §input        $Parent | parent object of the new object | object
# §input        $hInfo | attribute name => value hash (passed to insert()) | ref.hash
# §return       $hValues | hash with default attribute values (name => value) | ref.hash
#========================================================================================
sub default {
  my $class = shift;
  my ($Parent, $hInfo) = @_;

  return {
    %{$class->SUPER::default($Parent, $hInfo)},
    'displayType' => 2 # page
  };
}

1;
