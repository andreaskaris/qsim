#!/usr/bin/perl
use 5.10.0;
use strict;
use warnings;
use Data::Dumper;

sub create_datamap() {
    my $simulation_file = $_[0];

    my @datamaps = ();
    my @headers = ();
    my @values = ();

    open(SIMULATION_FILE, '<' . $simulation_file);

    my $line;
    my $c = -1;
    my $l = -1;
    while($line = <SIMULATION_FILE>) {
	if($line =~ /^\#/) {
	    $c++;
	    $l = -1;
	    $datamaps[$c] = ();
	    @headers = split(' ', $line);
	    foreach my $e (@headers) {
		$datamaps[$c]{$e} = ();
	    }
	} else {
	    $l++;
	    @values = split(' ', $line);
	    for(my $i = 0; $i < scalar(@values); $i++) {
		my $formatted_value =  $values[$i];
		if($formatted_value =~ /^-?(?:\d+(?:\.\d*)?&\.\d+)$/) {
		    $formatted_value = sprintf("%.3f" ,$formatted_value);
		} 
		$datamaps[$c]{$headers[$i]}[$l] = $formatted_value;
	    }
	}
    }

    close(SIMULATION_FILE);
    return @datamaps;
}

sub get_simulation_directory {
    my $simulation_id = $_[0];
    my $simulation_directory = 'simulations/' . $simulation_id . '/';
    return $simulation_directory;
}

sub get_simulation_file {
    my $simulation_id = $_[0];
    my $simulation_directory = get_simulation_directory($simulation_id);
    my $simulation_file = $simulation_directory . 'simulation.txt';
    return $simulation_file;
}

1;
