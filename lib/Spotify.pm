#!/usr/bin/env perl
package Spotify;
use base 'Exporter';
use 5.14.2;
use strict;
use warnings;
our @EXPORT_OK = qw(dummy);

############################################################
#
#=item dummy()
#
#This is a draft function.  
#
#Input:  @draft, [ $DEBUG ]
#
#Output: { FAILED => <0|1>, ANSWER => <string> }
#=cut
#
############################################################
sub dummy {
   return 0;
}

1;

__END__
=head1 NAME

Spotify - Basic Perl wrapper for the Spotify Web API

=head1 SYNOPSIS
TODO

=head1 DESCRIPTION
Basic Perl wrapper for the Spotify Web API with a minimum set of dependencies for the Raspberry Pi

=head1 CAVEATS
TODO

=head1 ACKNOWLEDGMENTS
Hexxeh

=head1 LICENSE
The Artistic License 2.0

=head1 AVAILABILITY
See http://github.com/stephanmg/spotify_web

=head1 AUTHOR
Stephan Grein <stephan@syntaktischer-zucker.de>

=head1 SEE ALSO
https://github.com/obrie/spotify_web
https://github.com/Hexxeh/spotify-websocket-api
