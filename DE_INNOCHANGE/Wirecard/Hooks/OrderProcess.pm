#========================================================================================
# §package      DE_INNOCHANGE::Wirecard::Hooks::OrderProcess
# §state        public
#----------------------------------------------------------------------------------------
# §description  Add or remove the order process step
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
package DE_INNOCHANGE::Wirecard::Hooks::OrderProcess;

use strict;
use DE_EPAGES::ExternalPayment::API::Constants qw (DEFAULT_PAYMENT_STEP_POSITION);

#========================================================================================
# §function     OnRegisterCheckoutProcess
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       OnRegisterCheckoutProcess($hParams);
#----------------------------------------------------------------------------------------
# §description  register payment step for checkout process
#----------------------------------------------------------------------------------------
# §input        $hParams | hook arguments, used keys are
#               <ul>
#                   <li>Servlet - servlet - object</li>
#                   <li>BasketOrderProcess - basket order process - object</li>
#               </ul> | ref.hash.*
#========================================================================================
sub OnRegisterCheckoutProcess {
  my ($hParams) = @_;
  my $Servlet = $hParams->{'Servlet'};
  my $BasketOrderProcess = $hParams->{'BasketOrderProcess'};

  my $BasketOrder = $Servlet->object;
  my $Container = $BasketOrder->container;
  return unless defined $Container;

  my $pli = $Container->get('Payment');
  return unless defined($pli);

  if ($pli->instanceOf('LineItemPaymentICWirecard')) {
    $BasketOrderProcess->addStep('ICWirecard', DEFAULT_PAYMENT_STEP_POSITION);
  }
  return;
}

#========================================================================================
# §function     AfterRegisterCheckoutProcess
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       AfterRegisterCheckoutProcess($hParams);
#----------------------------------------------------------------------------------------
# §description  set order step; remove payment step if necessary
#----------------------------------------------------------------------------------------
# §input        $hParams | hook arguments, used keys are
#               <ul>
#                   <li>Servlet - servlet - object</li>
#                   <li>BasketOrderProcess - basket order process - object</li>
#               </ul> | ref.hash.*
#========================================================================================
sub AfterRegisterCheckoutProcess {
  my ($hParams) = @_;
  my $Servlet = $hParams->{'Servlet'};
  my $BasketOrderProcess = $hParams->{'BasketOrderProcess'};

  my $BasketOrder = $Servlet->object;
  my $Container = $BasketOrder->container;
  return unless defined $Container;

  my $pli = $Container->get('Payment');
  return unless defined $pli;

  if ($pli->instanceOf('LineItemPaymentICWirecard')) {
    if ($pli->get('PaymentMethod')->get('DoPaymentOnBasket')) {
      $BasketOrderProcess->setOrderStep('ICWirecard');
    }
  }
  else {
    $BasketOrderProcess->deleteStep('ICWirecard');
  }

  return;
}

1;
