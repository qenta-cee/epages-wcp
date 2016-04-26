#========================================================================================
# §package      DE_INNOCHANGE::Wirecard::API::Cartridge
# §base         DE_EPAGES::Payment::API::PaymentInstaller
# §state        public
#----------------------------------------------------------------------------------------
# §description  This is the main cartridge class for install/patch/uninstall.
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
package DE_INNOCHANGE::Wirecard::API::Cartridge;
use base DE_EPAGES::Payment::API::PaymentInstaller;

use strict;

#========================================================================================
# §function     new
# §state        private
#----------------------------------------------------------------------------------------
# §syntax       $Installer = DE_INNOCHANGE::Wirecard::API::Cartridge->new(%options);
#----------------------------------------------------------------------------------------
# §description  Creates a new installer object of DE_INNOCHANGE::Wirecard.
#----------------------------------------------------------------------------------------
# §input        %options | options for un/install
#               <ul>
#                 <li>IsRecursive - recursive un/installation of required or dependent
#                     cartridges
#               </ul>
#               | hash
# §return       $Installer | cartridge installer | object
#========================================================================================
sub new {
    my ($class, %options) = @_;

    my $self = __PACKAGE__->SUPER::new(
        %options,
        'CartridgeDirectory' => 'DE_INNOCHANGE/Wirecard',
        'Version'            => '6.15.3',
        'Patches'            => [],
    );
    return bless $self, $class;
}

#========================================================================================
# §function     install
# §state        private
#----------------------------------------------------------------------------------------
# §syntax       $Installer->install;
#----------------------------------------------------------------------------------------
# §description  Installs the cartridge.
#========================================================================================
sub install {
    my $self = shift;

    $self->startInstall;
    $self->SUPER::install;
    $self->finishInstall;
    return;
}

#========================================================================================
# §function     uninstall
# §state        private
#----------------------------------------------------------------------------------------
# §syntax       $Installer->uninstall;
#----------------------------------------------------------------------------------------
# §description  Uninstalls the cartridge.
#========================================================================================
sub uninstall {
    my $self = shift;

    $self->startUninstall;
    $self->SUPER::uninstall;
    $self->finishUninstall;
    return;
}

1;
