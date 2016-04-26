#========================================================================================
# §package      DE_INNOCHANGE::Wirecard::API::Object::LineItemPaymentICWirecard
# §state        public
# §base         DE_EPAGES::ExternalPayment::API::Object::LineItemPaymentExternal
# §description  object interface for LineItemPaymentICWirecard.
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
package DE_INNOCHANGE::Wirecard::API::Object::LineItemPaymentICWirecard;
use base DE_EPAGES::ExternalPayment::API::Object::LineItemPaymentExternal;

use strict;
use HTTP::Status qw (HTTP_FOUND);
use DE_EPAGES::Core::API::Error qw (Error);
use DE_EPAGES::Trigger::API::Trigger qw (TriggerHook);
use DE_INNOCHANGE::Wirecard::API::Constants qw (DISPLAY_TYPE_PAGE);
use DE_INNOCHANGE::Wirecard::API::Payment qw (InitTransaction);

#========================================================================================
# §function     className
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $ClassName = $LineItemPaymentICWirecard->className;
#----------------------------------------------------------------------------------------
# §description  Returns the class name, used for DAL access.
#----------------------------------------------------------------------------------------
# §return       $ClassName | class name | String
#========================================================================================
sub className  { 'LineItemPaymentICWirecard' }

#========================================================================================
# §function     insert
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $LineItemPaymentICWirecard = DE_INNOCHANGE::Wirecard::API::Object::LineItemPaymentICWirecard->insert($hInfo);
# §example      my $Class = LoadClassByAlias('LineItemPaymentICWirecard');
#               my $LineItemPaymentICWirecard = $Class->insertObject($hInfo);
#----------------------------------------------------------------------------------------
# §description  Insert this info as object, afterwards the hook 'OBJ_InsertLineItemPaymentICWirecard' is triggered.
#----------------------------------------------------------------------------------------
# §input        $Package | class package | string
# §input        $hInfo | attributes of new object | ref.hash
# §return       $LineItemPaymentICWirecard | new object | object
# §hook         OBJ_InsertLineItemPaymentICWirecard | hook parameter keys :
#               <ul>
#                 <li>Object                      - this object          - object
#                 <li>LineItemPaymentICWirecardID - line item payment id - int
#               </ul>
#========================================================================================
sub insert {
  my ($Package, $hInfo) = @_;

  my $self = $Package->SUPER::insert($hInfo);

  TriggerHook('OBJ_InsertLineItemPaymentICWirecard', {'Object' => $self, 'LineItemPaymentICWirecardID' => $self->id });
  return $self;
}

#========================================================================================
# §function     delete
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $LineItemPaymentICWirecard->delete;
#----------------------------------------------------------------------------------------
# §description  Deletes this object, therefore the hook 'OBJ_DeleteLineItemPaymentICWirecard' is triggered.
#----------------------------------------------------------------------------------------
# §hook         OBJ_DeleteLineItemPaymentICWirecard | hook parameter keys :
#               <ul>
#                 <li>Object                      - this object          - object
#                 <li>LineItemPaymentICWirecardID - line item payment id - int
#               </ul>
#========================================================================================
sub delete {
  my $self = shift;

  TriggerHook('OBJ_DeleteLineItemPaymentICWirecard', {'Object' => $self, 'LineItemPaymentICWirecardID' => $self->id });
  $self->SUPER::delete;
  return;
}

#========================================================================================
# §function     set
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $LineItemPaymentICWirecard->set($hValues, $LanguageID);
#----------------------------------------------------------------------------------------
# §description  This function triggers hooks 'OBJ_BeforeUpdateLineItemPaymentICWirecard' and 'OBJ_AfterUpdateLineItemPaymentICWirecard'.
#----------------------------------------------------------------------------------------
# §hook         OBJ_BeforeUpdateLineItemPaymentICWirecard | hook parameter keys :
#               <ul>
#                 <li>Object        - this object          - object
#                 <li>LineItemPaymentICWirecardID - line item payment id - int
#                 <li>Values        - new values for object - ref.hash
#                 <li>LanguageID    - values of this language will be updated - int
#               </ul>
# §hook         OBJ_AfterUpdateLineItemPaymentICWirecard | hook parameter keys :
#               <ul>
#                 <li>Object        - this object          - object
#                 <li>LineItemPaymentICWirecardID - line item payment id - int
#                 <li>Values        - updated values       - ref.hash
#                 <li>LanguageID    - values updated of this language - int
#               </ul>
#----------------------------------------------------------------------------------------
# §input        $hValues | values to set | ref.hash
# §input        $LanguageID | language id for localized attributes | int
#========================================================================================
sub set {
  my $self = shift;
  my ($hValues, $LanguageID) = @_;

  TriggerHook('OBJ_BeforeUpdateLineItemPaymentICWirecard', {'Object'=>$self, 'Values'=> $hValues, 'LineItemPaymentICWirecardID' => $self->id, 'LanguageID' => $LanguageID});
  $self->SUPER::set($hValues, $LanguageID);
  TriggerHook('OBJ_AfterUpdateLineItemPaymentICWirecard',  {'Object'=>$self, 'Values'=> $hValues, 'LineItemPaymentICWirecardID' => $self->id, 'LanguageID' => $LanguageID});
  return;
}

#========================================================================================
# §function     executePayment
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $LineItemPaymentICWirecard->executePayment($hParams);
#----------------------------------------------------------------------------------------
# §description  init transaction request is sent to Wirecard; if successful, user is redirected to url returned
#----------------------------------------------------------------------------------------
# §input        $hValues | values witch will be changed | ref.hash
#========================================================================================
sub executePayment {
  my $self = shift;
  my ($hParams)= @_;

  $self->updateOnExecute($hParams);

  my $Object = $hParams->{'Order'} // $hParams->{'Basket'};
  my $Servlet = $hParams->{'Servlet'};
  my $Container = $self->container;

  my $redirectUrl = InitTransaction(
    $Container,
    $Servlet->params('REMOTE_ADDR'),
    $Servlet->requestHeaders('User-Agent'),
    $Servlet->vars('IsMobile')
  );
  if (defined($redirectUrl)) { # init successful
    my $displayType = $self->get('PaymentMethod')->get('displayType');
    if ($displayType == DISPLAY_TYPE_PAGE) { # show payment pages in same browser window
      $Servlet->vars('ExitAfterEvent', 1);
      my $Response = $Servlet->response;
      $Response->code(HTTP_FOUND);
      $Response->header('Location', $redirectUrl);
    }
    else {
      $Servlet->vars('redirectUrl', $redirectUrl);
      $Servlet->vars('displayType', $displayType);
    }
  }

  # code below is needed also in success case and displayType DISPLAY_TYPE_PAGE to stop the order from being created
  $Servlet->vars('ObjectID', $Object->id);

  Error('INVALID_FORM', {
    'ViewVars'=> {
    'FormError'    => 0,
    'ViewObjectID' => $Object->id,
  },
    'ViewAction' => 'ViewPaymentICWirecard'
  });
  return;
}

#========================================================================================
# §function     default
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $hValues = DE_INNOCHANGE::Wirecard::API::Object::LineItemPaymentICWirecard->default( $Parent, $hInfo );
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

  my $hDefault = $class->SUPER::default($Parent, $hInfo);
  if (defined($hInfo->{'PaymentMethod'})) {
    $hDefault->{'InternalMethod'} = $hInfo->{'PaymentMethod'}->get('paymentType');
  }
  return $hDefault;
}

#========================================================================================
# §function     updateOnExecute
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $PaymentLineItem->updateOnExecute;
#----------------------------------------------------------------------------------------
# §description  overwrite the function from the super class
#----------------------------------------------------------------------------------------
# §input        $hParams | input from super function | ref.hash
#========================================================================================
sub updateOnExecute {
  my $self = shift;
  my ($hParams)= @_;

  $self->SUPER::updateOnExecute($hParams);

  my $PaymentMethod = $self->get('PaymentMethod');
  $self->set({
    'InternalMethod'  => $PaymentMethod->get('paymentType'),
    'TransactionType' => $PaymentMethod->get('TransactionType')
  });
  return;
}

1;
