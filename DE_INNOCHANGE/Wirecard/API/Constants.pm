#========================================================================================
# §package      DE_INNOCHANGE::Wirecard::API::Constants
# §state        public
#----------------------------------------------------------------------------------------
# §description  constants for wirecard
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
package DE_INNOCHANGE::Wirecard::API::Constants;
use base Exporter;

use strict;
our @EXPORT_OK = qw (
  DISPLAY_TYPE_IFRAME
  DISPLAY_TYPE_PAGE
  DISPLAY_TYPE_POPUP
  @PARAMS_NO_COMMENT
  TRANS_TYPE_AUTHORIZED
  TRANS_TYPE_DECLINED
  TRANS_TYPE_SETTLED
  WC_PAYMENT_TYPE_INVOICE
  WC_PAYMENT_TYPE_INSTALLMENT
  WC_PAYMENT_TYPE_SELECT
  %WC_PAYMENT_TYPES
);

use constant WC_PAYMENT_TYPE_SELECT  => 'SELECT';
use constant WC_PAYMENT_TYPE_INVOICE => 'INVOICE';
use constant WC_PAYMENT_TYPE_INSTALLMENT => 'INSTALLMENT';

our %WC_PAYMENT_TYPES = (
  #'SELECT'                => '',
  'BANCONTACT_MISTERCASH' => 'Bancontact',
  'CCARD'                 => 'Credit Card',
  'EKONTO'                => 'eKonto',
  'SEPA-DD'               => 'SEPA Direct Debit',
  'EPS'                   => 'EPS e-payment',
  'GIROPAY'               => 'giropay',
  'IDL'                   => 'iDEAL',
  'INSTALLMENT'           => 'Installment',
  'INVOICE'               => 'Invoice',
  'MAESTRO'               => 'Maestro SecureCode',
  'MONETA'                => 'moneta.ru',
  'PRZELEWY24'            => 'Przelewy24',
  'PAYPAL'                => 'PayPal',
  'PBX'                   => 'Paybox',
  'POLI'                  => 'POLi payments',
  'PSC'                   => 'Paysafecard',
  'QUICK'                 => 'Quick',
  'SKRILLWALLET'          => 'Skrill Digital Wallet',
  'SOFORTUEBERWEISUNG'    => 'sofort.com',
  'TRUSTLY'               => 'Trustly'
);

use constant TRANS_TYPE_AUTHORIZED => 'authorized';
use constant TRANS_TYPE_SETTLED    => 'settled';
use constant TRANS_TYPE_DECLINED   => 'declined';

use constant DISPLAY_TYPE_POPUP  => 1;
use constant DISPLAY_TYPE_PAGE   => 2;
use constant DISPLAY_TYPE_IFRAME => 3;

# don't add the following fields to the order comment
our @PARAMS_NO_COMMENT = qw (responseFingerprint paymentState ic_paymentGUID responseFingerprintOrder);

1;
