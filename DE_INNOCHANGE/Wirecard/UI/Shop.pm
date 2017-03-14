#========================================================================================
# §package      DE_INNOCHANGE::Wirecard::UI::Shop
# §base         DE_EPAGES::Presentation::UI::Object
# §state        public
#----------------------------------------------------------------------------------------
# §description  ui functions for class shop
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
package DE_INNOCHANGE::Wirecard::UI::Shop;
use base DE_EPAGES::Presentation::UI::Object;

use strict;
use DE_EPAGES::Core::API::PerlTools qw (fcmp isValid);
use DE_EPAGES::Database::API::Connection qw (GetCurrentDBHandle);
use DE_EPAGES::ExternalPayment::API::Log qw (LogPayment);
use DE_EPAGES::Object::API::Factory qw (ExistsObjectByGUID LoadObjectByGUID);
use DE_EPAGES::Order::UI::Basket;
use DE_INNOCHANGE::Wirecard::API::Constants qw (@PARAMS_NO_COMMENT TRANS_TYPE_AUTHORIZED TRANS_TYPE_DECLINED TRANS_TYPE_SETTLED);
use DE_INNOCHANGE::Wirecard::API::Payment qw (CalculateFingerprint);

#========================================================================================
# §function     PaymentSuccessICWirecard
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $Package->PaymentSuccessICWirecard($Servlet);
#----------------------------------------------------------------------------------------
# §description  customer is redirected to this url in case of success
#----------------------------------------------------------------------------------------
# §input        $Servlet | servlet | object
#========================================================================================
sub PaymentSuccessICWirecard {
  my $self = shift;
  my ($Servlet) = @_;

  my $hFormValues = _getFormValues($Servlet);
  LogPayment('ICWirecard', 'PaymentSuccessICWirecard', $hFormValues);

  return _PaymentSuccess($Servlet, $hFormValues);
}

#========================================================================================
# §function     PaymentPendingICWirecard
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $Package->PaymentPendingICWirecard($Servlet);
#----------------------------------------------------------------------------------------
# §description  customer is redirected to this url in case of pending
#----------------------------------------------------------------------------------------
# §input        $Servlet | servlet | object
#========================================================================================
sub PaymentPendingICWirecard {
  my $self = shift;
  my ($Servlet) = @_;

  my $hFormValues = _getFormValues($Servlet);
  LogPayment('ICWirecard', 'PaymentPendingICWirecard', $hFormValues);

  return _PaymentSuccess($Servlet, $hFormValues);
}

#========================================================================================
# §function     PaymentConfirmICWirecard
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $Package->PaymentConfirmICWirecard($Servlet);
#----------------------------------------------------------------------------------------
# §description  server to server notification about successful or pending payment
#----------------------------------------------------------------------------------------
# §input        $Servlet | servlet | object
#========================================================================================
sub PaymentConfirmICWirecard {
  my $self = shift;
  my ($Servlet) = @_;

  my $hFormValues = _getFormValues($Servlet);
  LogPayment('ICWirecard', 'PaymentConfirmICWirecard', $hFormValues);

  my $Order = _PaymentSuccess($Servlet, $hFormValues, 1);

  if (!defined $Order) { # ensure an error message is set in error case
    my $errorMessage = $Servlet->vars('ICWirecardResultMessage');
    $Servlet->vars('ICWirecardResultMessage', 'internal error') unless defined($errorMessage);
  }
  return;
}

#========================================================================================
# §function     SendPaymentConfirmICWirecardResponse
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $Package->SendPaymentConfirmICWirecardResponse($Servlet);
#----------------------------------------------------------------------------------------
# §description  send response for PaymentConfirmWirecard; this must be done in a ViewAction
#----------------------------------------------------------------------------------------
# §input        $Servlet | servlet | object
#========================================================================================
sub SendPaymentConfirmICWirecardResponse {
  my $self = shift;
  my ($Servlet) = @_;

  my $errorMessage = $Servlet->vars('ICWirecardResultMessage');
  my $resultContent = defined($errorMessage)  ?
    qq(<QPAY-CONFIRMATION-RESPONSE result="NOK" message="$errorMessage" />)
    :
    qq(<QPAY-CONFIRMATION-RESPONSE result="OK" />);
  $Servlet->vars('ExitAfterEvent', 1);
  $Servlet->params('ContentType', 'text/xml');
  $Servlet->writeContentOutput($resultContent);
  return;
}

#========================================================================================
# §function     _PaymentSuccess
# §state        private
#----------------------------------------------------------------------------------------
# §syntax       _PaymentSuccess($Servlet, $hFormValues);
#----------------------------------------------------------------------------------------
# §description  handle successful and pending payment
#----------------------------------------------------------------------------------------
# §input        $Servlet | servlet | object
# §input        $hFormValues | form values | ref.hash
# §input        $NoFormError | don't add/execute form errors on error (optional, defaults to false) | boolean
#========================================================================================
sub _PaymentSuccess {
  my ($Servlet, $hFormValues, $NoFormError) = @_;

  my $hValues = _TestSuccessParameters($Servlet, $hFormValues, $NoFormError);
  my $PaymentLineItem = delete($hValues->{'PaymentLineItem'});
  return undef unless defined $PaymentLineItem;
  my $BasketOrder = $PaymentLineItem->container->parent;
  if (exists($hValues->{'Error'})) {
    if ($NoFormError) {
      $Servlet->vars('ICWirecardResultMessage', $hValues->{'Error'});
      return undef;
    }
    $Servlet->vars('PaymentObject', $BasketOrder->tleHash);
    $Servlet->vars('PaymentError', $hValues->{'Error'});
    $Servlet->vars('ViewAction', 'ViewPaymentICWirecardError');
    return;
  }
  # success
  $PaymentLineItem->set($hValues);

  # create order
  my $Order = $BasketOrder->instanceOf('Basket')  ?  DE_EPAGES::Order::UI::Basket->doBasket2Order($Servlet, $BasketOrder) : $BasketOrder;

  my $Status = 'PendingOn';
  if ($hFormValues->{'paymentState'} eq 'SUCCESS') {
    if ($PaymentLineItem->get('TransactionType')) {
      # authorization only
      $Status = $PaymentLineItem->get('PaymentMethod')->get('OrderStatusAuthorized');
    }
    else {
      # settle
      $Status = $PaymentLineItem->get('PaymentMethod')->get('OrderStatusSettled');
    }
  }
  my %OrderUpdate = ();
  $OrderUpdate{$Status} = GetCurrentDBHandle->currentDateTime() if (defined $Status);
  $OrderUpdate{'Comment'} = join("\n", map { "$_: $hFormValues->{$_}" } grep { !($_ ~~ @PARAMS_NO_COMMENT) } keys %$hFormValues);
  $Order->set(\%OrderUpdate);

  if ($hFormValues->{'paymentState'} eq 'SUCCESS') {
    return $Order; # show order confirmation page
  }
  # confirmation page with pending
  $Servlet->vars('Object', $Order);
  $Servlet->vars('ViewAction', 'ViewPaymentICWirecardPending');
  return;
}

#========================================================================================
# §function     _TestSuccessParameters
# §state        private
#----------------------------------------------------------------------------------------
# §syntax       my $hValues = _TestSuccessParameters($Servlet, $hFormValues);
#----------------------------------------------------------------------------------------
# §description  test callback parameters in success case
#----------------------------------------------------------------------------------------
# §input        $Servlet | servlet | object
# §input        $hFormValues | form values | ref.hash
# §input        $NoFormError | don't add/execute form errors if payment line item not found (optional, defaults to false) | boolean
# §return       $hValues | hash containing the payment line item and the values to set for it | ref.hash
#========================================================================================
sub _TestSuccessParameters {
  my ($Servlet, $hFormValues, $NoFormError) = @_;

  my $PaymentLineItem = _getPaymentLineItem($Servlet, $hFormValues, $NoFormError);
  return {'Error' => 'NoPaymentLineItem'} unless defined $PaymentLineItem;
  my $PaymentMethod = $PaymentLineItem->get('PaymentMethod');

  # check fingerprint
  my $expectedFingerprint = CalculateFingerprint($PaymentMethod->get('secret'), $hFormValues->{'responseFingerprintOrder'}, $hFormValues);

  if ($hFormValues->{'responseFingerprint'} ne $expectedFingerprint) {
    LogPayment('ICWirecard', 'fingerprint mismatch', {'received' => $hFormValues->{'responseFingerprint'}, 'calculated' => $expectedFingerprint});
    return {'PaymentLineItem' => $PaymentLineItem, 'Error' => 'fingerprintMismatch'};
  }

  my $TransactionType = 'PendingOn';

  # no amount, currency check for pending
  if ($hFormValues->{'paymentState'} eq 'SUCCESS') {
    # check amount/currency
    if (fcmp($hFormValues->{'amount'}, $PaymentLineItem->get('Amount')) != 0) {
      LogPayment('ICWirecard', 'amount mismatch', {'received' => $hFormValues->{'amount'}, 'expected' => $PaymentLineItem->get('Amount')});
      return {'PaymentLineItem' => $PaymentLineItem, 'Error' => 'amountMismatch'};
    }
    if ($hFormValues->{'currency'} ne $PaymentLineItem->get('CurrencyID')) {
      LogPayment('ICWirecard', 'currency mismatch', {'received' => $hFormValues->{'currency'}, 'expected' => $PaymentLineItem->get('CurrencyID')});
      return {'PaymentLineItem' => $PaymentLineItem, 'Error' => 'currencyMismatch'};
    }
    $TransactionType = $PaymentLineItem->get('TransactionType') ? TRANS_TYPE_AUTHORIZED : TRANS_TYPE_SETTLED;
  }

  # check payment state
  if ($hFormValues->{'paymentState'} ne 'SUCCESS' && $hFormValues->{'paymentState'} ne 'PENDING') {
    LogPayment('ICWirecard', 'paymentState', {'received' => $hFormValues->{'paymentState'}, 'expected' => 'SUCCESS', 'or' => 'PENDING'});
    return {'PaymentLineItem' => $PaymentLineItem, 'Error' => 'paymentState'};
  }

  my %Values = ('PaymentLineItem' => $PaymentLineItem);
  $Values{'AvsCode'}        = $hFormValues->{'avsResponseCode'}    if (isValid($hFormValues->{'avsResponseCode'}));
  $Values{'Message'}        = $hFormValues->{'avsResponseMessage'} if (isValid($hFormValues->{'avsResponseMessage'}));
  $Values{'TransID'}        = $hFormValues->{'orderNumber'}        if (isValid($hFormValues->{'orderNumber'}));
  $Values{'InternalMethod'} = $hFormValues->{'paymentType'}        if (isValid($hFormValues->{'paymentType'}));
  $Values{'TransStatus'}    = $TransactionType;
  $Values{'TransTime'}      = GetCurrentDBHandle()->currentDateTime;
  LogPayment('ICWirecard', 'callback values', \%Values);

  return \%Values;
}

#========================================================================================
# §function     _getPaymentLineItem
# §state        private
#----------------------------------------------------------------------------------------
# §syntax       my $PaymentLineItem = _getPaymentLineItem($Servlet, $hFormValues);
#----------------------------------------------------------------------------------------
# §description  get the payment line item from the callback parameters
#----------------------------------------------------------------------------------------
# §input        $Servlet | servlet | object
# §input        $hFormValues | form values | ref.hash
# §input        $NoFormError | don't add/execute form errors in error case, just return undef (optional, defaults to false) | boolean
# §return       $PaymentLineItem | payment line item | object
#========================================================================================
sub _getPaymentLineItem {
  my ($Servlet, $hFormValues, $NoFormError) = @_;
  my $PaymentLineItemGUID = $hFormValues->{'ic_paymentGUID'};
  LogPayment('ICWirecard', 'callback for payment line item ', $PaymentLineItemGUID);

  # check if object exists
  unless (defined($PaymentLineItemGUID) && ExistsObjectByGUID($PaymentLineItemGUID)) {
    LogPayment('ICWirecard', 'payment line item not found', $PaymentLineItemGUID);
    if ($NoFormError) {
      $Servlet->vars('ICWirecardResultMessage', 'invalid parameter ic_paymentGUID');
      return undef;
    }
    $Servlet->form->executeFormError( {
      'Name'       => 'PaymentLineItemGUID',
      'Reason'     => 'BadCallback_NoPaymentLineItem',
      'ViewAction' => 'ViewPaymentICWirecardError'
    });
  }

  # check object class
  my $PaymentLineItem = LoadObjectByGUID($PaymentLineItemGUID);
  if (!$PaymentLineItem->instanceOf('LineItemPaymentICWirecard')) {
    LogPayment('ICWirecard', 'payment line item is not an instance of PaymentLineItemICWirecard', $PaymentLineItem);
    if ($NoFormError) {
      $Servlet->vars('ICWirecardResultMessage', 'invalid parameter ic_paymentGUID');
      return undef;
    }
    $Servlet->form->executeFormError( {
      'Name'       => 'PaymentLineItemGUID',
      'Reason'     => 'BadCallback_WrongPaymentLineItem',
      'ViewAction' => 'ViewPaymentICWirecardError'
    });
  }

  # check shop
  if ($PaymentLineItem->getSite->id != $Servlet->object->id) {
    LogPayment('ICWirecard', 'payment line item does not belong to shop ' . $Servlet->object->alias, $PaymentLineItem);
    if ($NoFormError) {
      $Servlet->vars('ICWirecardResultMessage', 'invalid parameter ic_paymentGUID');
      return undef;
    }
    $Servlet->form->executeFormError( {
      'Name'       => 'PaymentLineItemGUID',
      'Reason'     => 'BadCallback_WrongShopPaymentLineItem',
      'ViewAction' => 'ViewPaymentICWirecardError'
    });
  }
  return $PaymentLineItem;
}

#========================================================================================
# §function     PaymentFailureICWirecard
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $Package->PaymentFailureICWirecard($Servlet);
#----------------------------------------------------------------------------------------
# §description  customer is redirected here in case of declined payment or error
#----------------------------------------------------------------------------------------
# §input        $Servlet | servlet | object
#========================================================================================
sub PaymentFailureICWirecard {
  my $self = shift;
  my ($Servlet) = @_;

  my $hFormValues = _getFormValues($Servlet);
  LogPayment('ICWirecard', 'PaymentFailureICWirecard', $hFormValues);

  my $PaymentLineItem = _getPaymentLineItem($Servlet, $hFormValues);
  $PaymentLineItem->set({
    'TransStatus' => TRANS_TYPE_DECLINED,
    'TransTime'   => GetCurrentDBHandle()->currentDateTime
  });

  # save failed payment to ordertable
  my $BasketOrder = $PaymentLineItem->container->parent;
  my $Order = $BasketOrder->instanceOf('Basket') ? DE_EPAGES::Order::UI::Basket->doBasket2Order($Servlet, $BasketOrder) : $BasketOrder;
  my $Status = 'CancelledOn';
  my %OrderUpdate = ();
  $OrderUpdate{$Status} = GetCurrentDBHandle->currentDateTime() if (defined $Status);
  $OrderUpdate{'Comment'} = $hFormValues->{'consumerMessage'};
  $Order->set(\%OrderUpdate);

  $Servlet->vars('PaymentObject', $PaymentLineItem->container->parent->tleHash);
  $Servlet->vars('consumerMessage', $hFormValues->{'consumerMessage'});
  $Servlet->vars('ViewAction', 'ViewPaymentICWirecardError');

  # if payment on order is possible in future cancel order here

  return;
}

#========================================================================================
# §function     _getFormValues
# §state        private
#----------------------------------------------------------------------------------------
# §syntax       my $hFormValues = _getFormValues($Servlet);
#----------------------------------------------------------------------------------------
# §description  get the form values as key/value hash
#               $Servlet->formValues returns a hash with array as values which is not handy
#----------------------------------------------------------------------------------------
# §input        $Servlet | servlet | object
# §return       $hFormValues | key/value hash with form values | ref.hash
#========================================================================================
sub _getFormValues {
  my ($Servlet) = @_;

  my $hFormValues = $Servlet->form->formValues;
  return {map { $_ => $hFormValues->{$_}->[0] } keys %$hFormValues};
}

1;
