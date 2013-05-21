#!/usr/bin/perl

use strict;
use 5.10.0;
use warnings;

my $perl = `which perl`;
chomp($perl);
 
my $param = '';
my $params = '';
if(!defined $ARGV[0]){
    $params = '';
} else {
    while($param = shift(@ARGV)) {
	$params .= $param . ' ';
    }
}

my $output;
my $return_code;
my $cmd = "${perl} qsim.pl ${params}";
say $cmd;
$output = qx($cmd);
$return_code=$?;
chomp($output);
if($return_code) {
    say $output;
    exit 1;
}


$cmd = "${perl} qplot.pl --simulation-id=${output}";
say $cmd;
$output = qx($cmd);
$return_code=$?;
chomp($output);
if($return_code) {
    say $output;
    exit 1;
}

$cmd = "${perl} qhtml.pl --simulation-id=${output}";
say $cmd;
$output = qx($cmd);
$return_code=$?;
chomp($output);
if($return_code) {
    say $output;
    exit 1;
}

if($output) {
    say "Simulation ${output} successful";
}

