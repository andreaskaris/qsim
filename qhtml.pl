#!/usr/bin/perl
##########################################
# Generate HTML document for simulation 
# --simulation-id=x
#
##########################################
use strict;
use warnings;
use 5.10.0;

use Chart::Graph::Gnuplot qw(gnuplot);
use Data::Dumper;
use Getopt::Long;

require './helpers.pl';

##########################################
# User vars
##########################################
my $simulation_id = ''; 

##########################################
# System vars
##########################################
my @datamaps = ();
my %datamap = ();
my @plots = ();
my $sim_id = time();
my $blueprint_html = 'blueprint.html';
my $html = 'simulation.html';
my $simulation_num = 0;
my $show_help = 0;

###########################################
# Getopts
###########################################
########################################### 
# Get CLI options
###########################################
sub getopt {
    my $help;
    my $result = GetOptions (
	"simulation-id=s" => \$simulation_id,
	"help|h"  => \$help);  # flag

    if(!$result || $help) {
	$show_help = 1;
    }
}

########################################### 
# Show online help
###########################################
sub show_help {
    say 'qplot.pl';
    say '--simulation-id  Mandatory, provide simulation id';
    say '                 this is the timestamp of the simulation';
    say '                 directory';
    say 'Example:';
    say './qplot.pl --simulation-id 1368905006';
}

###############################################
# Main starts here ...
###############################################
getopt();
if($show_help == 1 || !$simulation_id) {
    show_help();
    exit 1;
}

# determine simulation directory and simulation raw input file
# see helpers.pl for more information
my $simulation_directory = get_simulation_directory($simulation_id);
my $simulation_file = get_simulation_file($simulation_id);
my $html_file = $simulation_directory . 'simulation.html';
if(!-f $simulation_file) {
    say 'Error: Simulation file ' . $simulation_file . ' does not exist';
    exit 1;
}

#read all input from blueprint.html
open(BLUEPRINT_HTML, '<' . $blueprint_html);
#output everything to simulation.html file
open(HTML_OUT, '>' . $html_file);
#create datamap from simulation.txt
@datamaps = create_datamap($simulation_file);
#determine number of simulations that qsim.pl ran
$simulation_num = scalar @datamaps;

#create a page (tab) for each simulation
my $sim_num = 1;
my $line;
my $tabs = '';
my $tab = '';
for(my $sim_num = 1; $sim_num <= $simulation_num; $sim_num++) {
    #get total number of events (lines in simulation.txt) that occured in this simulation
    my $event_num = scalar @{$datamaps[$sim_num - 1]{'t'}};

    #get datamap for current simulation
    my $datamap = $datamaps[$sim_num - 1];

    #some statistics to show in the html
    my $time;
    my $queue_lengths = '';
    my $B;
    my $Y;
    my $avg_arrival_rates = '';
    my $avg_drop_rates = '';
    my $aB;
    my $abs_arrivals = '';
    my $abs_drops = '';

    $time = $datamap->{'t'}[$event_num - 1];
    $B = 'B: ' . $datamap->{'B'}[$event_num - 1] . '<br />';
    $Y = 'Y: ' .$datamap->{'Y'}[$event_num - 1] . '<br />';
    $aB = 'aB: ' . $datamap->{'aB'}[$event_num - 1] . '<br />';
    for(my $i = 1; defined($datamap->{'ql' . $i}); $i++) {
	$queue_lengths .= "Queue length ${i}: " . $datamap->{'ql' . $i}[$event_num - 1] . '<br />';
    }
    for(my $i = 1; defined($datamap->{'aA' . $i}); $i++) {
	$avg_arrival_rates .= "Average arrival rate ${i}: " . $datamap->{'aA' . $i}[$event_num - 1] . '<br />';
    }
    for(my $i = 1; defined($datamap->{'aD' . $i}); $i++) {
	$avg_drop_rates .= "Average drop rate ${i}: " . $datamap->{'aD' . $i}[$event_num - 1] . '<br />';
    }
    for(my $i = 1; defined($datamap->{'A' . $i}); $i++) {
	$abs_arrivals .= "Abs arrival ${i}: " . $datamap->{'A' . $i}[$event_num - 1] . '<br />';
    }
    for(my $i = 1; defined($datamap->{'D' . $i}); $i++) {
	$abs_drops .= "Abs drops ${i}: " . $datamap->{'D' . $i}[$event_num - 1] . '<br />';
    }

    $tab .= <<END;
<div id="tabs-${sim_num}" style="text-align:center;">
    <h3>System state at the end of the simulation</h3>
    <p>
      Time: ${time}<br />
      Number of events: ${event_num}
    </p>
    <img src='sim_${sim_num}_length.png' />
    <p>
      ${queue_lengths}
      ${B}
      ${Y} 
    </p>
    <img src='sim_${sim_num}_avg.png' />
    <p>
      ${avg_arrival_rates}
      ${avg_drop_rates}
      ${aB}
    </p>
    <img src='sim_${sim_num}_abs.png' />
    <p>
      ${abs_arrivals}
      ${abs_drops}
    </p>
  </div>
END
    $tabs .="<li><a href=\"#tabs-${sim_num}\">sim_${sim_num}</a></li>";
}

#replace all markers inside blueprint.html
my $data_id = $simulation_num + 1;
$tabs .="<li><a href=\"#tabs-${data_id}\">raw data</a></li>";
while(<BLUEPRINT_HTML>) {
    $line = $_;
    $line =~ s/###NUM###/$sim_num/g;
    $line =~ s/###ID###/$simulation_id/g;
    $line =~ s/###TAB###/$tab/g;
    $line =~ s/###TABS###/$tabs/g;
    $line =~ s/###DATA_ID###/${data_id}/g;

    print HTML_OUT $line;
}

close(BLUEPRINT_HTML);
close(HTML_OUT);
