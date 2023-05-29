#!perl
use 5.014; # //, strict, say, s//r
use warnings;   no warnings 'redefine';
use lib './lib';
use Win32::GUI::P5PL;
if(!caller){Win32::GUI::P5PL::App->launch();}

sub setup() {
  createCanvas(400, 400);
}

sub draw() {
  background(220);
}
