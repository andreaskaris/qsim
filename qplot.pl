#!/usr/bin/perl
use strict;
use warnings;
use 5.10.0;

use Chart::Graph::Gnuplot qw(gnuplot);
use Data::Dumper;
use Getopt::Long;

require './helpers.pl';

my $simulation_id = ''; 
my @datamaps = ();
my %datamap = ();
my @plots = ();
my $show_help = 0;

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

my $simulation_directory = get_simulation_directory($simulation_id);
my $simulation_file = get_simulation_file($simulation_id);
if(!-f $simulation_file) {
    say 'Error: Simulation file ' . $simulation_file . ' does not exist';
    exit 1;
}

@datamaps = create_datamap($simulation_file);
my $datamap;
my $sim_num = 0;

foreach (@datamaps) {
    my $datamap = $_;

    $sim_num++;
    
    #############################################
    # prepare data for plots
    # length plot
    #############################################
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
    foreach my $index ('B', 'Y') {
	if(defined($datamap->{$index})) {
	    push(@plots, [
		     {'title' => $index,
		      'style' => ($index eq 'B') ? 'points' : 'steps',
		      'type' => 'columns',
		     }, 
		     $datamap->{'t'},
		     $datamap->{$index}
		 ]);
	}
    }
    
    gnuplot({'title' => 'Simulation #' . $simulation_id,
	     'x2-axis label' => 'Analysis of simulation #' . $simulation_id. ' run # ' . $sim_num,
	     #'logscale x2' => '1',
	     #'logscale y' => '1',
	     'output type' => 'png',
	     'output file' => $simulation_directory . 'sim_' . $sim_num . '_length.png',
	     'x-axis label' => 'Time',
	     'y-axis label' => 'Occurrences',
	     #'xtics' => [ ['small\nfoo', 10], ['medium\nfoo', 20], ['large\nfoo', 30] ],
	     'extra_opts' => 'set key left top Left'
	    },
	    @plots
	);
 
    #############################################
    # prepare data for plots
    # avg plot
    # aB    aA1    aA2    aD1    aD2
    #############################################
    @plots = ();
    #plot all queues 
    for(my $i = 1; defined($datamap->{'aA' . $i}); $i++) {
	push(@plots, [
		 {'title' => 'Average arrival rate ' . $i,
		  'style' => 'steps',
		  'type' => 'columns'
		 }, 
		 $datamap->{'t'},
		 $datamap->{'aA' . $i}
	     ]);
    }
    for(my $i = 1; defined($datamap->{'aD' . $i}); $i++) {
	push(@plots, [
		 {'title' => 'Average drop rate ' . $i,
		  'style' => 'steps',
		  'type' => 'columns'
		 }, 
		 $datamap->{'t'},
		 $datamap->{'aD' . $i}
	     ]);
    }
    #add data about service business, if it exists
    foreach my $index ('aB') {
	if(defined($datamap->{$index})) {
	    push(@plots, [
		     {'title' => $index,
		      'style' => 'steps',
		      'type' => 'columns',
		     }, 
		     $datamap->{'t'},
		     $datamap->{$index}
		 ]);
	}
    }
    
    gnuplot({'title' => 'Simulation #' . $simulation_id,
	     'x2-axis label' => 'Analysis of simulation #' . $simulation_id. ' run # ' . $sim_num,
	     #'logscale x2' => '1',
	     #'logscale y' => '1',
	     'output type' => 'png',
	     'output file' => $simulation_directory . 'sim_' . $sim_num . '_avg.png',
	     'x-axis label' => 'Time',
	     'y-axis label' => 'Avg rate',
	     #'xtics' => [ ['small\nfoo', 10], ['medium\nfoo', 20], ['large\nfoo', 30] ],
	     'extra_opts' => 'set key left top Left'
	    },
	    @plots
	);

    #############################################
    # prepare data for plots
    # abs plot
    # A1     A2     D1     D2
    #############################################
    @plots = ();
    #plot all queues 
    for(my $i = 1; defined($datamap->{'A' . $i}); $i++) {
	push(@plots, [
		 {'title' => 'Absolute arrivals ' . $i,
		  'style' => 'steps',
		  'type' => 'columns'
		 }, 
		 $datamap->{'t'},
		 $datamap->{'A' . $i}
	     ]);
    }
    for(my $i = 1; defined($datamap->{'D' . $i}); $i++) {
	push(@plots, [
		 {'title' => 'Absolute drops ' . $i,
		  'style' => 'steps',
		  'type' => 'columns'
		 }, 
		 $datamap->{'t'},
		 $datamap->{'D' . $i}
	     ]);
    }
    #plot absolute time busy
    push(@plots, [
	     {'title' => 'Absolute time busy',
	      'style' => 'steps',
	      'type' => 'columns'
	     }, 
	     $datamap->{'t'},
	     $datamap->{'tB'}
	 ]);
    
    gnuplot({'title' => 'Simulation #' . $simulation_id,
	     'x2-axis label' => 'Analysis of simulation #' . $simulation_id. ' run # ' . $sim_num,
	     #'logscale x2' => '1',
	     #'logscale y' => '1',
	     'output type' => 'png',
	     'output file' => $simulation_directory . 'sim_' . $sim_num . '_abs.png',
	     'x-axis label' => 'Time',
	     'y-axis label' => 'Abs',
	     #'xtics' => [ ['small\nfoo', 10], ['medium\nfoo', 20], ['large\nfoo', 30] ],
	     'extra_opts' => 'set key left top Left'
	    },
	    @plots
	);
}

say $simulation_id;

exit 0;
