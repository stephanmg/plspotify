#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: prepare.pl
#
#        USAGE: ./prepare.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 10/08/2013 14:28:21
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

use lib './lib/';
use MyInit;

init_auth();
init_favs();
