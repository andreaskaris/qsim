#!/usr/bin/perl

use strict;
use 5.10.0;

use Chart::Graph::Gnuplot qw(gnuplot);
use Data::Dumper;

require './helpers.pl';

my %datamap = create_datamap();

my $sim_id = time();

#prepare data for plots
my @plots = ();
#plot all queues
for(my $i = 1; defined($datamap{'ql' . $i}); $i++) {
    push(@plots, [
	     {'title' => 'Queue length ' . $i,
	      'style' => 'steps',
	      'type' => 'columns'
	     }, 
	     $datamap{'t'},
	     $datamap{'ql' . $i}
	 ]);
}
#add data about service business, it it exists
if(defined($datamap{'B'})) {
    push(@plots, [
	     {'title' => 'Queue length 1',
	      'style' => 'steps',
	      'type' => 'columns'
	     }, 
	     $datamap{'t'},
	     $datamap{'B'}
	 ]);
}
    
gnuplot({'title' => 'Simulation #' . $sim_id,
	 'x2-axis label' => 'Analysis of simulation #' . $sim_id,
	 #'logscale x2' => '1',
	 #'logscale y' => '1',
	 'output type' => 'png',
	 'output file' => 'gnuplot1.png',
	 'x-axis label' => 'Time',
	 'y-axis label' => 'Occurrences',
	 #'xtics' => [ ['small\nfoo', 10], ['medium\nfoo', 20], ['large\nfoo', 30] ],
	 'extra_opts' => 'set key left top Left'
	},
	@plots
);
