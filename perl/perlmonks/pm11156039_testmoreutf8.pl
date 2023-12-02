#!perl

use 5.008;
use strict;
use warnings;
use Test::More tests => 1;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Encode;

BEGIN {
    if($ARGV[0]) {
        binmode Test::More->builder->$_, ':utf8' for qw/failure_output todo_output output/;
    }
}

$| = 1;
my $smile = "☺";

diag "This smile $smile will ", ($ARGV[0]?'not ':''), "warn";

is $smile, Encode::decode('UTF-8', "\xE2\x98\xBA"), "equivalent smiles";
