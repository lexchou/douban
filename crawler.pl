#!/usr/bin/perl
use warnings;
use strict;
use LWP::UserAgent;
use Template;
use utf8;
use Encode;
use POSIX;
use Date::Parse;
use DBI;
use YAML::XS qw(LoadFile);

my $conf = LoadFile("config.yaml");

my $ua = new LWP::UserAgent(agent => "$conf->{headers}->{'User-Agent'}");
my $dbh = DBI->connect("DBI:mysql:database=$conf->{database}->{schema};host=$conf->{database}->{host}", $conf->{database}->{user}, $conf->{database}->{password});
$dbh->{mysql_enable_utf8} = 1;
$dbh->do('set names utf8;');
sub get
{
	my ($url, $referer) = @_;
    my %headers = %{$conf->{headers}};
    $headers{Referer} = $referer;
    my $resp = $ua->get($url, %headers);
    return $resp->content;
}

sub load_topic_list
{
	my ($groupId) = @_;
	my $url = "http://www.douban.com/group/$groupId/discussion";
	my $content = get($url, 'http://www.douban.com/');
	my @ret = $content =~ m/http:\/\/www.douban.com\/group\/topic\/(\d+)\//g;
	print "No topic list received from $url\n" unless scalar(@ret);
	return @ret;
}
sub load_topic
{
	my ($groupId, $topicId) = @_;
	my $content = get("http://www.douban.com/group/topic/$topicId/", 'http://www.douban.com/group/$groupId/discussion');
	my ($title) = $content =~ m/<title>\s*(.*)\s*<\/title>/g;
	my @pictures = $content =~ m/http:\/\/img\d+.douban.com\/view\/group_topic\/large\/public\/\w+.jpg/g;
    my ($uid, $nick, $time) = $content =~ m/<a href="http:\/\/www.douban.com\/group\/people\/([\-\w]+)\/">([^<]+)<\/a>[^<]*<\/span>\s+<span class="color-green">([\s\-:\d]+)<\/span>/g;
    $content =~ s/^.*<div class="topic-content">\s*//smg;
    $content =~ s/<\/div>\s*<\/div>\s*<\/div>.*$//smg;
    $content =~ s/\r//smg;
    $content =~ s/>\s+</></smg;
    print "No author id for http://www.douban.com/group/topic/$topicId/\n" unless $uid;
	return {
		title => $title,
		userId => $uid,
		userName => $nick,
		timestamp => str2time($time),
		pictures => \@pictures,
		content => $content
	};
}

while(1)
{
	my $insert = $dbh->prepare("INSERT INTO `topics` VALUES(?, ?, ?, ?, ?, ?, ?, ?);");
	for my $group (@{$dbh->selectall_arrayref("SELECT `id`, `name`, `displayName` FROM `groups`", {Slice => {}})})
	{
		my $total = 0;
		for my $topicId(load_topic_list $group->{name})
		{
			my ($exists) = $dbh->selectrow_array("SELECT COUNT(1) FROM `topics` WHERE `id` = ?", {}, $topicId);
			next if $exists;
			my $topic = load_topic($group, $topicId);
		    my $pics = @{$topic->{pictures}};
		    $dbh->do("INSERT IGNORE INTO `people` VALUES(?, ?);", {}, $topic->{userId}, $topic->{userName});
			$insert->execute($topicId, $group->{id}, $topic->{userId}, $topic->{timestamp}, $pics ? 2 : 3, $pics, $topic->{title}, $pics ? $topic->{pictures}->[0] : '');
			$dbh->do("INSERT INTO `contents` VALUES(?, ?);", {}, $topicId, $topic->{content});
			$total++;
		}
		print "$total topics collected for $group->{displayName}\n";
	}
	sleep $conf->{crawlerSleep};
}
