use Test::More;
use strict;
use DE_EPAGES::Core::API::Error qw (ExistsError);
use DE_EPAGES::Core::API::File  qw( GetFileNames );
use DE_EPAGES::Core::API::PerlTools qw(UsePackage);
use DE_EPAGES::Core::API::Script qw( RunScript );

RunScript( Sub => sub {
    my $CartridgePackage = 'DE_INNOCHANGE::Wirecard';
    $CartridgePackage =~ s/::/\//g;
    my $aFileNames = GetFileNames( "$ENV{EPAGES_CARTRIDGES}/$CartridgePackage" , {'recursive' => 1} );
    my @Modules = map { /^\Q$ENV{EPAGES_CARTRIDGES}\E\/(.*)\.pm$/; $_ = $1; s/[\/]/::/g; $_; } grep { /\.pm$/ && !/Generated/ } @$aFileNames;

    plan tests => scalar @Modules;
    foreach my $Package (@Modules) {
        UsePackage( $Package );
        ok ( !ExistsError(), $Package);
    }
});
