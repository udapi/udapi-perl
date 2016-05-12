#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Udapi::Core::Run q(udapi_runner);
udapi_runner(\@ARGV);
