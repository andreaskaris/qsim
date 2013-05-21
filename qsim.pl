#!/usr/bin/perl
##########################################
# qsim.pl, v1.0
##########################################
use 5.10.0;
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Tie::IxHash;

##########################################
# User vars can be set via the command line
# See help file for more info
# $max_events stop simulation after x events
#   0 means don't consider no. of events
# $max_time stop simulation after time y
#   0 means don't consider time
# $max_events = 0 && $max_time = 0 
#   run simulation forever
# $lambda1 arrival rate for queue 1
# $lambda2 arrival rate for queue 2
# $mu service rate 
# $scheduling_strategy Scheduling strategy, one of the 
#   following
#     --scheduling=least-time
#     --scheduling=round-robin
#     --scheduling=weight --weight1=x --weight2==y
# $weight1 Weight for $scheduling='weight'
#     --weight1=1
# $weight2
#     --weight2=1
# #max_simulations=1
#  how many consecutive simulations
##########################################
my $max_events = 0; 
my $max_time = 0; 
my $lambda1 = 0.5;
my $lambda2 = 0.5;
my $mu = 1.0;
my $scheduling_strategy = 'least-time';
my $weight1 = 1;
my $weight2 = 1;
my $max_simulations = 1;
my $max_queue_length1 = 0;
my $max_queue_length2 = 0;
my $verbose = 0;
my $simulation_id = '';
my $of; #outfile

##########################################
# Global variables
##########################################
###########################################
# System vars
# %c1 contains information about index and arrival time of next 
# event for queue 1
#    'index' all client events have a unique index in order of their
#    generation
#    'time' time when the client event joined the system
# %c2 contains information about index and arrival time of next 
# event for queue 2
#    'index' all client events have a unique index in order of their
#    generation
#    'time' time when the client event joined the system
# $client use at the beginning of each iteration; if bit 0 is set
# to 1, this means that the system needs to generate a new future
# event for %c1. if bit 1 is set to 1, the system will generate a 
# new future event for %c2, and so forth. Note that both bits might
# be  set at the same time, or no bit at all
###########################################
my %c1 = ('index' => 0, 'time' => 0); #client 1 time
my %c2 = ('index' => 0, 'time' => 0); #client 2 time
my $client = 3; #which client has just been served - in binary! bit 0 -> client 1, bit 1 -> client2

###########################################
# System state (current queue and service point
# states)
# @queue1 Array (FIFO) representing queue1 and containing all
# events that arrived at queue1 and that the service could not
# process yet
# @queue2 Array (FIFO) representing queue1 and containing all
# events that arrived at queue1 and that the service could not
# process yet
# %service current state of the service point
#   'end_time' future end of the service operation
#   'client_index' index of element which is currently being served
###########################################
#current system time
my $time = 0; #current time
my $old_time = 0; #system time at last run
#queues and service
my @queue1 = (); #queue 1
my @queue2 = (); #queue 2
my %service = ( 'end_time' => 0,
                'client_index' => 0);

###########################################
# Stats vars (store stats for each iteration about system)
# Used to print system state at the end of each iteration
###########################################
tie(my %stats, 'Tie::IxHash');

###########################################
# Online help
###########################################
my $show_help = 0;
sub show_help {
    say 'qsim.pl version 1';
    say '';
    say '--simulation-id mandatory simulation identifier';
    say '--max-events stop simulation after x events';
    say '  0 means do not consider no. of events';
    say '    default: 0';
    say '--max-time stop simulation after time y';
    say '  0 means do not consider time';
    say '    default: 0';
    say '--max-events=0 && --max-time=0';
    say '  run simulation forever';
    say '--lambda1 arrival rate for queue 1';
    say '    default: 0.3';
    say '--lambda2 arrival rate for queue 2';
    say '    default: 0.3';
    say '--mu service rate';
    say '    default: 1.0';
    say '--max-queue-length1 Length of queue 1 where 0 means unlimited';
    say '    default: 0';
    say '--max-queue-length2 Length of queue 2 where 0 means unlimited';
    say '    default: 0';
    say '--scheduling Scheduling strategy, one of the following:';
    say '  least-time';
    say '  round-robin';
    say '  weight';
    say '    default: least-time';
    say '--weight1 Weight for --scheduling="weight"';
    say '    default: 1';
    say '--weight2 Weight for --scheduling="weight"';
    say '    default: 1';
    say '';
    say 'Example:';
    say './qsim.pl --simulation-id=mysim simulation --mu=1 --lambda1=0.3 --lambda2=0.4 \\';
    say '--max-events=0 --max-time=100 --scheduling=least-time \\';
    say '--max-queue-length1=5 --max-queue-length2=10 --max-simulations=10';
    say '';
}

###########################################
# Getopts
###########################################
#get CLI options
sub getopt {
    my $help;
    my $result = GetOptions (
	"simulation-id=s" => \$simulation_id,
	"max-events=i" => \$max_events,
	"max-time=f" => \$max_time,
	"lambda1=f" => \$lambda1,
	"lambda2=f" => \$lambda2,
	"mu=f" => \$mu,
	"scheduling_strategy=s" => \$scheduling_strategy,
	"weight1=f" => \$weight1,
	"weight2=f" => \$weight2,
	"max-simulations=i" => \$max_simulations,
	"max-queue-length1=i" => \$max_queue_length1,
	"max-queue-length2=i" => \$max_queue_length2,
	"verbose|v" => \$verbose,
	"help|h"  => \$help);  # flag

    if(!$result || !$simulation_id || $help) {
	$show_help = 1;
    }
}

###########################################
# Simulation methods
###########################################
###########################################
#terminate last job; serve new element after termination
###########################################
sub terminate_job {
    $service{'end_time'} = 0;
    $service{'client_index'} = 0;
    serve();
}

###########################################
#push event to one of the two queues and serve the event right away if the service is empty
#%c push this event to the queue
#$q push to this queue number
###########################################
sub enqueue {
    my %c = %{$_[0]};
    my $q = $_[1];
    if($q == 1) {
	if($max_queue_length1 && scalar @queue1 >= $max_queue_length1) {
	    $stats{'d1'} = $c{'index'};
	    $stats{'D1'}++;
	} else {
	    push(@queue1, $c{'index'}); 
	}
    } else {
	if($max_queue_length2 && scalar @queue2 >= $max_queue_length2) {
	    $stats{'d2'} = $c{'index'};
	    $stats{'D2'}++;
	} else {
	    push(@queue2, $c{'index'});
	}
    }
    
    #a new job might be enqueued and served right away .. but ...
    #if the current job isn't done yet, don't fetch a new job
    $service{'end_time'} = 0 if(!$service{'end_time'});
    $c{'time'} = 0 if(!$c{'time'});
    if($c{'time'} >= $service{'end_time'}) {
	serve();
    }
}

###########################################
# Serve a new client according to the scheduler's decision
# might be 'take client from queue1', 'take client from queue2',
# 'do not serve any clients right now'
# if the service decides to serve a new client, it calculates
# the service end time based on $mu 
###########################################
sub serve {
    #run the scheduler which decides where to fetch the next packet
    my $schedule = schedule();
    if($schedule == 1) {
	#Fetching event from queue
	$service{'client_index'} = shift(@queue1);
    } elsif($schedule == 2) {
	#Fetching event from queue 2
	$service{'client_index'} = shift(@queue2);
    } else {
	return;
    }

    #add service flag
    $stats{'f'} .= 's';
    #set end time of this service job
    $service{'end_time'} = $time + (-1/$mu) * log(rand());
}

###########################################
# Schedule a new client
# Take client either from queue 1 or queue 2,
# based on the scheduling strategy
# Don't do anything if both queues are empty.
# If only one queue is empty, select client from
# the other queue
# Else decide based on scheduling algorithm
# $scheduling_strategy Scheduling strategy, one of the 
#   following
#     --scheduling=least-time
#     --scheduling=round-robin
#     --scheduling=weight --weight1=x --weight2==y
# $weight1 Weight for $scheduling='weight'
#     --weight1=1
# $weight2
#     --weight2=1
###########################################
sub schedule {
    #both queues are empty, nothing to schedule
    if(!@queue1 && !@queue2) {
	return 0;
    }
    #if queue1 empty, select element from queue 2
    if(!@queue1) {
	return 2;
    }
    #if queue2 empty, select element from queue 1
    if(!@queue2) {
	return 1;
    }

    given($scheduling_strategy) {
	when('round-robin') {
	    say "Round robin scheduling not implemented yet";
	    exit 1;
	}
	when('weight') {
	    say "Weight scheduling not implemented yet";
	    exit 1;
	}
	default {
            #schedule based on client event index 
	    #(=client event age)
	    if($queue1[0] < $queue2[0]) {
		return 1;
	    } else {
		return 2;
	    }	    
	}
    }
}

############################################
# Print line for event table
#a1 arrival event 1
#a2 arrival event 2
#s service point
#e end for element
#d element was dropped
#ql1 queue length 1
#ql2 queue length 2
#f flag (a_rrival, e_nd, s_service, d_rop
############################################
sub print_line {
    my $t = $time;
    my $stats = $_[0];
    my $pattern = '';
    while( my ($k, $v) = each %$stats ) {
	$v = 0 if(!defined($v)); #if $v is not initialized, set it to 0
	if($k eq 'f') {
	    $pattern = "%s\t";
	} elsif ($v =~ /^-?\d+$/) { #integer
	    $pattern = "% 7d\t";
	} elsif($v =~ /^\d+\.\d+/) { #decimal number
	    $pattern = "% 7.3f\t";
	} else {
	    $pattern = "% 7s\t";
	}
	printf($pattern, $v) if($verbose);
	printf($of $pattern, $v);
    }
    printf("\n") if($verbose);
    printf($of "\n");
}

############################################
# Print header for event table
############################################
sub print_header {
    my $stats = $_[0];
    printf("#") if($verbose);
    printf($of "#");
    while( my ($k, $v) = each %$stats ) { 
	if($k eq 'f') {
	    printf("%s\t", $k) if($verbose);
	    printf($of "%s\t", $k);
	} else {
	    printf("% 7s\t", $k) if($verbose);
	    printf($of "% 7s\t", $k);
	}
    }
    printf("\n") if($verbose);
    printf($of "\n");
}

##########################################
# Reset the stats counter
# resets hash of stats
# @soft_or_hard_reset 'soft' or 'hard', depending on which counters
# are set to 0
##########################################
sub reset_stats {
    my $soft_or_hard_reset = $_[0];
    $stats{'f'} = '';
    $stats{'t'} = $time;
    foreach my $i ('a1', 'a2', 's', 'e', 'd1', 'd2', 'ql1', 'ql2', 'Y', 'B', 'aB', 'aA1', 'aA2', 'aD1', 'aD2') {
	$stats{$i} = 0;
    }
    if($soft_or_hard_reset eq 'hard') {
	foreach my $i ('A1', 'A2', 'D1', 'D2', 'tB') {
	    $stats{$i} = 0;
	}
    }
}

###########################################
# Start application
###########################################
#get command line arguments and display help if needed
getopt();
if($show_help) {
    show_help();
    exit 1;
}

##########################################
# Storage
##########################################
my $outfile_dir = 'simulations/' . $simulation_id . '/';
my $outfile = $outfile_dir . 'simulation.txt';
if(! -d $outfile_dir) {
    mkdir($outfile_dir) or die 'Could not create directory ' . $outfile_dir;
}
open($of, '> ' . $outfile) or die 'Could not open log file';

my $simulation_no = 0;
for(my $sim_num = 0; $sim_num < $max_simulations;$sim_num++) {
    %c1 = ('index' => 0, 'time' => 0); #client 1 time
    %c2 = ('index' => 0, 'time' => 0); #client 2 time
    $client = 3; 
    $time = 0; #current time
    $old_time = 0; #system time at last run of loop
    @queue1 = (); #queue 1
    @queue2 = (); #queue 2
    %service = ( 'end_time' => 0,
		 'client_index' => 0);
    reset_stats('hard');
    $stats{'f'} = 'b';
    print_header(\%stats); #print header first
    print_line(\%stats); #print null event
    my $i = 0;
  THIS_SIMULATION:
    while(1)
    {   
	$old_time = $time;

	#if max_events and max_time equal to 0 -> run forever
	#else run until max_events or max_time reached, whichever occurs
	# first
	if($max_events > 0 && $max_time > 0) {
	    last THIS_SIMULATION if($i >= $max_events);
	    last THIS_SIMULATION if($time >= $max_time);
	} elsif($max_events > 0) {
	    last THIS_SIMULATION if($i >= $max_events);
	} elsif($max_time > 0) {
	    last THIS_SIMULATION if($time >= $max_time);
	}

	reset_stats('soft'); #reset all stats to 0
	
	#first run: recalculates both client event times
	#subsequent runs: recalculates either client event time
	#if bit 1 is set, then increment $c1
	if($client & 1) {
	    $i++;
	    $c1{'index'} = $i;
	    $c1{'time'} = 0 if(!$c1{'time'});
	    $c1{'time'} = $c1{'time'} + (-1 / $lambda1) * log(rand());
	}
	#if bit 2 is set, then increment $c2
	if($client & 2) {
	    $i++;
	    $c2{'index'} = $i;
	    $c2{'time'} = 0 if(!$c2{'time'});
	    $c2{'time'} = $c2{'time'} + (-1 / $lambda2) * log(rand());
	}

	#job end event first? -> terminate job
	$service{'client_index'} = 0 if !$service{'client_index'};
	if($service{'client_index'} != 0 && $service{'end_time'} < $c1{'time'} && $service{'end_time'} < $c2{'time'}) {
	    $time = $service{'end_time'};
	    #don't increment client event at next iteration
	    $client = 0; 
	    #stats{'e'} needs to be called BEFORE terminate_job
	    $stats{'e'} = $service{'client_index'}; 
	    #set end event flag
	    $stats{'f'} .= 'e';
	    #terminat the job
	    terminate_job();
	} 
	else {
	    #select client event that occurs first
	    if($c1{'time'} < $c2{'time'}) {
		$time = $c1{'time'};
		#increment client 1 event at next iteration
		$client = 1; 
		#push client event to queue 1
		enqueue(\%c1, 1);
		$stats{'a1'} = $c1{'index'};
		$stats{'A1'}++;
	    } else {
		$time = $c2{'time'};
		#increment client 3 event at next iteration
		$client = 2; 
		#push client event to queue 2
		enqueue(\%c2, 2);
		$stats{'a2'} = $c2{'index'};
		$stats{'A2'}++;
	    }
	    $stats{'f'} .= 'a';
	}

	$stats{'s'} = $service{'client_index'};
	$stats{'ql1'} = scalar @queue1;
	$stats{'ql2'} = scalar @queue2;
	$stats{'B'} = ($service{'end_time'} > 0) ? 1 : 0;
	$stats{'Y'} = $stats{'ql1'} + $stats{'ql2'} + $stats{'B'};
	$stats{'aA1'} = $stats{'A1'} / $time;
	$stats{'aA2'} = $stats{'A2'} / $time;
	$stats{'aD1'} = $stats{'D1'} / $time;
	$stats{'aD2'} = $stats{'D2'} / $time;
	$stats{'tB'} = ($time - $old_time) * $stats{'B'} + $stats{'tB'};
	$stats{'aB'} = $stats{'tB'} / $time;
	
	#print stats for this iteration
	print_line(\%stats);
    } 
}

close($of);

say '' . $simulation_id;
