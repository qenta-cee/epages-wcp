use Test::More;
use strict;

use DE_EPAGES::Core::API::Script qw( RunScript );
use DE_INNOCHANGE::Wirecard::API::Cartridge;

RunScript(
    Sub => sub {
        my $Cartridge = DE_INNOCHANGE::Wirecard::API::Cartridge->new();
        $Cartridge->test();
        done_testing();
    }
);
