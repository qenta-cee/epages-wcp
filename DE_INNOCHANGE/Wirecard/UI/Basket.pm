#========================================================================================
# §package      DE_INNOCHANGE::Wirecard::UI::Basket
# §base         DE_EPAGES::Presentation::UI::Object
# §state        public
#----------------------------------------------------------------------------------------
# §description  ui functions for class basket
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
package DE_INNOCHANGE::Wirecard::UI::Basket;
use base DE_EPAGES::Presentation::UI::Object;

use strict;
use HTTP::Status qw (HTTP_FOUND);
use DE_INNOCHANGE::Wirecard::API::Constants qw (DISPLAY_TYPE_PAGE);
use DE_INNOCHANGE::Wirecard::API::Payment qw (InitTransaction);

#========================================================================================
# §function     ViewMultiPaymentICWirecard
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       $Package->ViewMultiPaymentICWirecard($Servlet);
#----------------------------------------------------------------------------------------
# §description  start the payment for multi step checkout
#----------------------------------------------------------------------------------------
# §input        $Servlet | servlet | object
#========================================================================================
sub ViewMultiPaymentICWirecard {
  my $self = shift;
  my ($Servlet) = @_;

  my $Basket = $Servlet->object;

  my $redirectUrl = InitTransaction(
    $Basket->container,
    $Servlet->params('REMOTE_ADDR'),
    $Servlet->requestHeaders('User-Agent'),
    $Servlet->vars('IsMobile')
  );
  if (defined($redirectUrl)) { # init successful
    my $displayType = $Basket->container->get('Payment')->get('PaymentMethod')->get('displayType');
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
  # show error page; the same template as for success and display types DISPLAY_TYPE_POPUP and DISPLAY_TYPE_IFRAME is used
  return;
}

1;
