#!/usr/bin/perl

use warnings;
use strict;
#use lib '.';
#use myModule;
use Math::Vector::Real::Intersect;

# print "Hello World\n"

sub ThisHereFunction {

    my ( $x, $y, $z ) = @_;
    return 0;
}
sub SomePackage::this_is_another_function {

}

sub this_is_another_function2 {
}

sub this_is_another_function1 {
}


my $t  = ThisHereFunction();
my $t2 = SomePackage::this_is_another_function();
my $t3 = this_is_another_function1();
my $t4 = this_is_another_function2();
this_is_another_function1();


__DATA__
1. Install [most recent perlnavigator.exe](https://github.com/bscan/PerlNavigator/releases)
2. Install [most recent NppLspPlugin](https://github.com/Ekopalypse/NppLspClient/tags) (or from the 0.27-alpha that eko emailed me)
    - the zip he emailed had a "PDF" in it, but just rename that to "DLL" and it works
3. Messes up old debugger plugin, which I never used anyway, so remove/disable that
4. Config File: append the following to NppLspClient.toml
    ```
    [lspservers.perl]
    mode = "io"
    executable = 'c:\usr\local\bin\perlnavigator.exe'
    args = '--stdio'
    auto_start_server = true
    ```
4. Show the Console and Symbols panels in the plugin

I don't know if there's a way yet to add options in NppLspClient.toml... but if there is, I want to be able to set
    settings.perlnavigator.includePaths = $workspaceFolder;$workspaceFolder/lib;$workspaceFolder/..;$workspaceFolder/../lib;
or something similar, so that script.pl and t\test.t will both be able to the see the project's lib folder... but I don't think eko's
plugin has that feature as of the 0.27-alpha from April.
