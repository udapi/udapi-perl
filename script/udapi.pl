#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use Udapi::Core::Run q(udapi_runner);
udapi_runner(\@ARGV);
