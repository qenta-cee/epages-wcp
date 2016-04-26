#========================================================================================
# §package      DE_INNOCHANGE::Wirecard::Hooks::Attribute
# §state        public
#----------------------------------------------------------------------------------------
# §description  provide attributes configurable in PBO
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
package DE_INNOCHANGE::Wirecard::Hooks::Attribute;

use strict;
use DE_EPAGES::Object::API::Factory qw (LoadObjectByPath GetRootObjectID);
use DE_EPAGES::ThirdPartyConfig::API::Constants qw (ATTRIBUTES_CATEGORY_PAYMENT);

#========================================================================================
# §function     OnGetThirdPartyConfigAttributes
# §state        public
#----------------------------------------------------------------------------------------
# §syntax       OnGetThirdPartyConfigAttributes(\%Params);
#----------------------------------------------------------------------------------------
# §description  provide attributes configurable in PBO
#----------------------------------------------------------------------------------------
# §input        $hParams | hook params | ref.hash
#========================================================================================
sub OnGetThirdPartyConfigAttributes {
  my ($hParams) = @_;

  return unless $hParams->{'AttributesCategory'} eq ATTRIBUTES_CATEGORY_PAYMENT;

  my $PaymentType  = LoadObjectByPath('/PaymentTypes/ICWirecard');
  my $RootObjectID = GetRootObjectID();

  push(@{$hParams->{'Attributes'}}, {
    'SectionID'   => $PaymentType->alias,
    'SectionName' => $PaymentType->get('NameOrAlias', $hParams->{'LanguageID'}),
    'Attributes' => [
      {'ObjectID' => $PaymentType->id, 'AttributeAlias' => 'Logging'},
      {'ObjectID' => $RootObjectID,    'AttributeAlias' => 'ICWirecard_InitTransactionURL'}
    ]
  });

  return;
}

1;
