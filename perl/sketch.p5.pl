#!perl
use 5.014; # //, strict, say, s//r
use warnings;
use lib './lib';
use Win32::GUI::P5PL;
if(!caller){Win32::GUI::P5PL::App->launch();}

sub setup() {
  createCanvas(800, 400);
  background(220);
}

sub draw() {
    background(255,0,0);
}
