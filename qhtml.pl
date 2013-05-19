#!/usr/bin/perl
use strict;
use warnings;
use 5.10.0;

use Chart::Graph::Gnuplot qw(gnuplot);
use Data::Dumper;
use Getopt::Long;

require './helpers.pl';

my $simulation_id = ''; 
my $simulation_num = 0;
my @datamaps = ();
my %datamap = ();
my @plots = ();
my $sim_id = time();
my $show_help = 0;
my $blueprint_html = 'blueprint.html';
my $html = 'simulation.html';

###########################################
# Getopts
###########################################
#get CLI options
sub getopt {
    my $help;
    my $result = GetOptions (
	"simulation-id=s" => \$simulation_id,
	"simulation-num=s" => \$simulation_num,
	"help|h"  => \$help);  # flag

    if(!$result || $help) {
	$show_help = 1;
    }
}

sub show_help {
    say 'qplot.pl';
    say '--simulation-id  Mandatory, provide simulation id';
    say '                 this is the timestamp of the simulation';
    say '                 directory';
    say '--simulation-num  Mandatory, provide simulation id';
    say '                 this is the timestamp of the simulation';
    say '                 directory';
    say 'Example:';
    say './qplot.pl --simulation-id 1368905006';
}

###############################################
# Main
###############################################
getopt();
if($show_help == 1 || !$simulation_id) {
    show_help();
    exit 1;
}

my $simulation_directory = 'simulations/' . $simulation_id . '/';
my $simulation_file = $simulation_directory . 'simulation.txt';
my $html_file = $simulation_directory . 'simulation.html';
if(!-f $simulation_file) {
    say 'Error: Simulation file ' . $simulation_file . ' does not exist';
    exit 1;
}

#open(STDIN, '<' . $simulation_file);
open(STDIN, '<' . $blueprint_html);
open(STDOUT, '>' . $html_file);
#@datamaps = create_datamap();
#say scalar @datamaps;
#my $datamap;

my $sim_num = 1;
my $line;
my $tabs = '';
my $tab = '';
for(my $sim_num = 1; $sim_num <= $simulation_num; $sim_num++) {
    $tab .= <<END;
<div id="tabs-${sim_num}" style="text-align:center;">
    <img src='sim_${sim_num}_length.png' />
    <img src='sim_${sim_num}_avg.png' />
    <img src='sim_${sim_num}_abs.png' />
  </div>
END
    $tabs .="<li><a href=\"#tabs-${sim_num}\">sim_${sim_num}</a></li>";
}
my $data_id = $simulation_num + 1;
$tabs .="<li><a href=\"#tabs-${data_id}\">raw data</a></li>";
while(<STDIN>) {
    $line = $_;
    $line =~ s/###NUM###/$sim_num/g;
    $line =~ s/###ID###/$simulation_id/g;
    $line =~ s/###TAB###/$tab/g;
    $line =~ s/###TABS###/$tabs/g;
    $line =~ s/###DATA_ID###/${data_id}/g;

    print $line;
}

close(STDIN);
close(STDOUT);
