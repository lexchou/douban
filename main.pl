#!/usr/bin/env perl
use strict;
use warnings;
use CGI::Fast;
use router;
use douban;

while(my $q = new CGI::Fast)
{
    router::dispatch($q);
}
