#!/usr/bin/perl
use 5.10.0;
use strict;
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
	    @datamaps[$c] = {};
	    @headers = split(' ', $line);
	    foreach my $e (@headers) {
		$datamaps[$c]{$e} = ();
	    }
	} else {
	    $l++;
	    @values = split(' ', $line);
	    for(my $i = 0; $i < scalar(@values); $i++) {
		$datamaps[$c]{$headers[$i]}[$l] = sprintf("%.3f" ,$values[$i]);
	    }
	}
    }

    #push(@datamaps, %datamap);
    return @datamaps;
}


1;
