#========================================================================================
# §package      DE_INNOCHANGE::Wirecard::UI::PaymentMethodICWirecard
# §base         DE_EPAGES::Payment::UI::PaymentMethod
# §state        public
#----------------------------------------------------------------------------------------
# §description  UI functions for class PaymentMethodICWirecard
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
package DE_INNOCHANGE::Wirecard::UI::PaymentMethodICWirecard;
use base DE_EPAGES::Payment::UI::PaymentMethod;

use strict;
use DE_EPAGES::Object::API::Factory qw (LoadClassByAlias);
use DE_EPAGES::Order::API::Constants qw (ORDER_STATUS_ATTRIBUTES);
use DE_INNOCHANGE::Wirecard::API::Constants qw (
  %WC_PAYMENT_TYPES
  WC_PAYMENT_TYPE_INVOICE
  WC_PAYMENT_TYPE_INSTALLMENT
  WC_PAYMENT_TYPE_SELECT
);

#========================================================================================
# §function     ViewSettings
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $Package->ViewSettings($Servlet);
#----------------------------------------------------------------------------------------
# §description  view payment method settings page
#----------------------------------------------------------------------------------------
# §input        $Servlet | servlet | object
#========================================================================================
sub ViewSettings {
  my $self = shift;
  my ($Servlet) = @_;

  $Servlet->vars('WC_PAYMENT_TYPE_SELECT', WC_PAYMENT_TYPE_SELECT);
  $Servlet->vars('WC_PAYMENT_TYPE_INVOICE', WC_PAYMENT_TYPE_INVOICE);
  $Servlet->vars('WC_PAYMENT_TYPE_INSTALLMENT', WC_PAYMENT_TYPE_INSTALLMENT);
  $Servlet->vars('WC_PAYMENT_TYPES', [map { {'ID' => $_, 'Name' => $WC_PAYMENT_TYPES{$_}} } sort keys %WC_PAYMENT_TYPES]);

  # order status
  my $OrderClass = LoadClassByAlias('CustomerOrder');
  $Servlet->vars('OrderStatusAttributes', [map { $OrderClass->attribute($_)->tleHash } ORDER_STATUS_ATTRIBUTES]);

  return;
}

#========================================================================================
# §function     SaveSettings
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $Package->SaveSettings($Servlet);
#----------------------------------------------------------------------------------------
# §description  save the payment method settings
#----------------------------------------------------------------------------------------
# §input        $Servlet | servlet | object
#========================================================================================
sub SaveSettings {
  my $self = shift;
  my ($Servlet) = @_;

  my $Form = $Servlet->form;
  my $hFormValues = $Form->form($Servlet->object, 'ICWirecardSettings', 1);

  if (defined($hFormValues->{'paymentType'}) && !(exists($WC_PAYMENT_TYPES{$hFormValues->{'paymentType'}}) || $hFormValues->{'paymentType'} eq WC_PAYMENT_TYPE_SELECT)) {
    $Form->addFormError({
      'Name'   => 'paymentType',
      'Reason' => 'InvalidPaymentType',
      'Form'   => 'ICWirecardSettings'
    });
  }
  $Form->executeFormError;

  # normal save
  $self->Save($Servlet);

  # set sendAddressData to 1 if payment type is invoice
  my $PaymentMethod = $Servlet->object;
  if ($PaymentMethod->get('paymentType') eq WC_PAYMENT_TYPE_INVOICE) {
    $PaymentMethod->set({'sendBillingData' => 1});
    $PaymentMethod->set({'sendShippingData' => 1});
  }
  if ($PaymentMethod->get('paymentType') eq WC_PAYMENT_TYPE_INSTALLMENT) {
    $PaymentMethod->set({'sendBillingData' => 1});
    $PaymentMethod->set({'sendShippingData' => 1});
  }
  return;
}

1;
