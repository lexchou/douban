package router;
use strict;
use warnings;
use Scalar::Util qw(reftype);

my %routers = ();

sub not_found
{
    print "Status: 404\n";
    print "Content-Type: text/html\n\n";
    print<<EOF
<html>
<body>
<h1>404 Not found</h1>
Cannot find $ENV{REQUEST_URI}.
</body>
</html>
EOF
}

sub LOG
{
    open my $tty, '>:encoding(utf8)', '/dev/tty' or return;
    print $tty join(' ', @_) . "\n";
    close $tty;
}
sub add_rule
{
    my ($method, $path, $callback) = @_;
    my $handlers = $routers{$method};
    $handlers = $routers{$method} = {q1 => {}, q2 => []} if not $handlers;
    if(reftype($path))
    {
        push @{$handlers->{q2}}, [$path, $callback];
    }
    else
    {
        $handlers->{q1}->{$path} = $callback;
    }
}

sub get_handler
{
    my ($method, $uri) = @_;
    my $rulesByMethod = $routers{$method};
    return (not_found, []) unless $rulesByMethod;
    my $ret = $rulesByMethod->{q1}->{$uri};
    return $ret if $ret;
    for(@{$rulesByMethod->{q2}})
    {
        my @m = $uri =~ $_->[0];
        return ($_->[1], \@m) if @m;
    }

    return (not_found, []);
}

sub dispatch
{
    my $q = shift;
    my $method = $ENV{REQUEST_METHOD};
    my $uri = $ENV{REQUEST_URI};
    $uri =~ s/\?.*$//;
    LOG "$ENV{REMOTE_ADDR} $method $ENV{REQUEST_URI}";
    my ($handler, $args) = get_handler($method, $uri);
    eval
    {
	&$handler($q, @$args);
    };
    print STDERR "Failed to handle $method $uri: $@\n" if $@;
}



1;
