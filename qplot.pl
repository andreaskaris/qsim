#!/usr/bin/perl
use strict;
use 5.10.0;

use Chart::Graph::Gnuplot qw(gnuplot);
use Data::Dumper;
use Getopt::Long;

require './helpers.pl';

my $simulation_id = ''; 
my @datamaps = ();
my %datamap = {};
my @plots = ();
my $sim_id = time();
my $show_help;

###########################################
# Getopts
###########################################
#get CLI options
sub getopt {
    my $help;
    my $result = GetOptions (
	"simulation-id=s" => \$simulation_id,
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
if(!-f $simulation_file) {
    say 'Error: Simulation file ' . $simulation_file . ' does not exist';
    exit 1;
}

open(STDIN, '<' . $simulation_file);
@datamaps = create_datamap();
my $datamap;
my $sim_num = 0;

foreach (@datamaps) {
    my $datamap = $_;

    $sim_num++;
    #prepare data for plots
    @plots = ();
    #plot all queues
    for(my $i = 1; defined($datamap->{'ql' . $i}); $i++) {
	push(@plots, [
		 {'title' => 'Queue length ' . $i,
		  'style' => 'steps',
		  'type' => 'columns'
		 }, 
		 $datamap->{'t'},
		 $datamap->{'ql' . $i}
	     ]);
    }
#add data about service business, it it exists
    if(defined($datamap->{'B'})) {
	push(@plots, [
		 {'title' => 'Queue length 1',
		  'style' => 'steps',
		  'type' => 'columns'
		 }, 
		 $datamap->{'t'},
		 $datamap->{'B'}
	     ]);
    }
    
    gnuplot({'title' => 'Simulation #' . $sim_id,
	     'x2-axis label' => 'Analysis of simulation #' . $sim_id. ' run # ' . $sim_num,
	     #'logscale x2' => '1',
	     #'logscale y' => '1',
	     'output type' => 'png',
	     'output file' => $simulation_directory . 'plot_sim_' . $sim_num . '.png',
	     'x-axis label' => 'Time',
	     'y-axis label' => 'Occurrences',
	     #'xtics' => [ ['small\nfoo', 10], ['medium\nfoo', 20], ['large\nfoo', 30] ],
	     'extra_opts' => 'set key left top Left'
	    },
	    @plots
	);
}

close(STDIN);
