package douban;
use strict;
use warnings;
use router;
use Template;
use DBI;
use YAML::XS qw(LoadFile);
use JSON;
use utf8;
use Encode qw(decode_utf8);

-s "config.yaml" or die "Please rename config.yaml-template to config.yaml to start\n";
my $conf = LoadFile("config.yaml");

my $dbh = DBI->connect("DBI:mysql:database=$conf->{database}->{schema};host=$conf->{database}->{host}", $conf->{database}->{user}, $conf->{database}->{password});
$dbh->{mysql_enable_utf8} = 1;
$dbh->do("set names utf8;");
my $tt = new Template({INCLUDE_PATH => 'templates', INTERPOLATE => 1, ENCODING => 'utf8'});

sub getGroups
{
	return $dbh->selectall_arrayref("SELECT `id`, `name`, `displayName` FROM `groups`", {Slice => {}});
}
sub index
{
    my ($q) = @_;
    my $output = '';
    print $q->header('text/html');
    my $vars = {
    	activeGroup => 'haixiuzu',
    	groups => getGroups
    };
    
    $tt->process('index.html', $vars, $output) || die $tt->error();
    print $output;
}
sub render
{
    my ($q, $template, $vars) = @_;
    my $output = '';
    print $q->header('text/html;charset=utf8');
    $tt->process($template, $vars, $output, binmode => ':utf8') || die $tt->error();
    print $output;
}
sub group
{
    my ($q, $groupId) = @_;
    my $vars = {
    	groups => getGroups
    };
    for(@{$vars->{groups}})
    {
    	$vars->{activeGroup} = $_ if $_->{name} eq $groupId;
    }
    render($q, 'group.html', $vars);
}
sub deleted
{
    my $vars = {
    	groups => getGroups
    };
    render(shift, 'deleted.html', $vars);
}
sub latest
{
    my $vars = {
    	groups => getGroups
    };
    render(shift, 'latest.html', $vars);
}
sub query_topics
{
    my ($query, $since, $max) = @_;
    my $sql = "select topics.`id`, `timestamp`, `title`, people.name 'userName', people.id 'userId', `thumbUrl` 
        from topics, people where $query and topics.id < ? and topics.author = people.id order by id desc limit ?";
    my $res = $dbh->selectall_arrayref($sql, {Slice => {}}, $since, $max);
#from topics, people where topics.group = ? and topics.id < ? and topics.state = 2 and topics.author = people.id order by id desc limit ?", {Slice => {}}, $groupId, $since, $max);
    for(@$res)
    {
        my @thumbs = split /\n/, $_->{thumbUrl};
        $_->{thumbUrls} = \@thumbs;
        delete $_->{thumbUrl};
    }
    return $res;
}

sub list_deleted
{
	my ($q) = @_;
	print $q->header('application/json; charset = utf8');
	my $since = $q->param('id') || 1000000000;
	my $res = query_topics("topics.state = 3", $since, 20);
	print decode_utf8(encode_json({results => $res}));
}
sub list_latest
{
	my ($q) = @_;
	print $q->header('application/json; charset = utf8');
	my $since = $q->param('id') || 1000000000;
	my $res = query_topics("topics.state = 2", $since, 20);
	print decode_utf8(encode_json({results => $res}));
}
sub list
{
	my ($q, $groupName) = @_;
	print $q->header('application/json; charset = utf8');
	my $since = $q->param('id') || 1000000000;
	my ($groupId) = $dbh->selectrow_array("SELECT `id` FROM `groups` WHERE `name` = ?", {}, $groupName || '');
	my $res = [];
    $res = query_topics("topics.group = $groupId and topics.state = 2", $since, 20) if(defined($groupId));
	print decode_utf8(encode_json({results => $res}));
}
sub remove
{
	my ($q, $groupName, $topicId) = @_;
	print $q->header('application/json; charset = utf8');
	my $key = $q->cookie('key');
	if($key ne $conf->{removeKey})
	{
		print '{"success" : false}';
		return;
	}
	$dbh->do("UPDATE `topics` SET `state` = 3 WHERE `id` = ?", {}, $topicId);
	print '{"success" : true}';
}
sub get_content
{
	my ($q, $groupName, $topicId) = @_;
	print $q->header('text/html; charset = utf8');
	my ($content) = $dbh->selectrow_array("SELECT `content` FROM `contents` WHERE `id` = ?", {}, $topicId);
    print $content;
}


#router::add_rule('GET', '/douban', \&index);
router::add_rule('GET', qr/^\/douban\/latest$/, \&latest);
router::add_rule('GET', qr/^\/douban\/deleted$/, \&deleted);
router::add_rule('GET', qr/^\/douban\/(\w+)$/, \&group);
router::add_rule('GET', qr/^\/douban\/api\/latest$/, \&list_latest);
router::add_rule('GET', qr/^\/douban\/api\/deleted$/, \&list_deleted);
router::add_rule('GET', qr/^\/douban\/api\/(\w+)$/, \&list);
router::add_rule('GET', qr/^\/douban\/(\w+)\/list$/, \&list);
router::add_rule('DELETE', qr/^\/douban\/api\/(\w+)\/(\d+)$/, \&remove);
router::add_rule('GET', qr/^\/douban\/api\/(\w+)\/(\d+)$/, \&get_content);

1;
