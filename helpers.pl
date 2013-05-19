#!/usr/bin/perl
use 5.10.0;
use strict;
use warnings;
use Data::Dumper;

sub create_datamap() {
    my @datamaps = ();
    my @headers = ();
    my @values = ();

    my $line;
    my $c = -1;
    my $l = -1;
    while($line = <STDIN>) {
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

    #push(@datamaps, %datamap);
    return @datamaps;
}


1;
