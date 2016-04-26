#-*- Makefile -*-
require DE_EPAGES::Core::API::Makefile;
__DATA__

!OS_SPECIFIC_DEFINES
COMPANY     = DE_INNOCHANGE
CARTRIDGE   = Wirecard
MODELS      = "Models/Wirecard.pdm"
CVS_BRANCH  = main
STORE       =
RECURSIVE   =
EPAGES_PASSWORD = $(PASSWORD)
EPAGES_TESTSITE = $(STORE)
BUILDFILE=$(DE_EPAGES)/CodeGenerator/Templates/epages/BuildCentralDAL.xml

CVS_CARTRIDGESPATH =RND/epages/epages5/AllOS/Cartridges
CVS_PATH        = $(CVS_CARTRIDGESPATH)/$(COMPANY)/$(CARTRIDGE)
DE_EPAGES   = ../../DE_EPAGES
CARTRIDGES  = $(COMPANY)::$(CARTRIDGE)
COMPANY_CARTRIDGE = COMPANY=$(COMPANY) CARTRIDGE=$(CARTRIDGE) DE_EPAGES="$(DE_EPAGES)"
PRGS = PERL="$(PERL)" MKDIR="$(MKDIR)" RMDIR="$(RMDIR)"

MAKE_GENERATE   = $(MAKE) -f $(DE_EPAGES)/CodeGenerator/Scripts/CodeGenerator.mak $(COMPANY_CARTRIDGE) MODELS=$(MODELS) CVS_BRANCH=$(CVS_BRANCH) CVS_PATH=$(CVS_PATH) BUILDFILE=$(BUILDFILE) $(PRGS)
MAKE_CORE   = $(MAKE) -f $(DE_EPAGES)/Core/Scripts/Core.mak $(COMPANY_CARTRIDGE) $(PRGS)
MAKE_DOC    = $(MAKE) -f $(DE_EPAGES)/SourceDoc/Scripts/SourceDoc.mak $(COMPANY_CARTRIDGE) $(PRGS)
MAKE_INSTALL    = $(MAKE) -f $(DE_EPAGES)/Installer/Scripts/Installer.mak STORE=$(STORE) CARTRIDGES=$(CARTRIDGES) DE_EPAGES="$(DE_EPAGES)" OLDRELEASE=$(OLDRELEASE) NEWRELEASE=$(NEWRELEASE) CVS_CARTRIDGESPATH=$(CVS_CARTRIDGESPATH) $(PRGS) RECURSIVE=$(RECURSIVE)
MAKE_REGISTER   = $(MAKE) -f $(DE_EPAGES)/ShopConfiguration/Scripts/Register.mak CARTRIDGES=$(CARTRIDGES) DE_EPAGES="$(DE_EPAGES)" $(PRGS)

makefile: Makefile.PL
	$(PERL) Makefile.PL
	$(PERL) -e "print \"Please restart '$(MAKE)' again makefile was updated.\n\";exit 1;"

clean: makefile
	-$(DEL) .*#* *.pdb
	-$(DEL) makefile
	-$(RMDIR) Generated

generate generate_merge generate_update resolve_conficts: makefile
	$(MAKE_GENERATE) $@

install uninstall create_patch test_patch patch cpan: makefile
	$(MAKE_INSTALL) $@

register unregister: makefile
	$(MAKE_REGISTER) $@

sourcedoc: makefile
	$(MAKE_DOC) sourcedoc

test test_coverage collect_coverage coverage_report: makefile
	$(MAKE_CORE) $@
#
#   END
#
