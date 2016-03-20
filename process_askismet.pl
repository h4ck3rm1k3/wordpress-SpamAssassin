#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use XML::Simple;
use Encode qw(decode encode);
use Net::Akismet;
use secrets;

my $akismet = Net::Akismet->new(
    KEY => $secrets::key,
    URL => 'http://wiki.pirateparty.electionr.us/',
    ) or die('Key verification failure!');

my $file= shift;
my $xs = XML::Simple->new();
my $ref = $xs->XMLin($file, ForceArray => 1, KeyAttr => []);
my $posts = $ref->{channel}[0]->{item};


foreach my $post (@{$posts}) {
    if ($post->{'wp:post_type'}[0] =~ /^post|page$/) {

	warn  $post->{'title'}[0];
	
	for my $comment (@{ $post->{'wp:comment'}}) {
	    my $maild = $comment->{'wp:comment_content'}[0];
	    my $email = $comment->{'wp:comment_author_email'}[0];
	    my $author = $comment->{'wp:comment_author'}[0];
	    my $curl = $comment->{'wp:comment_author_url'}[0];
	    my $srcip = $comment->{'wp:comment_author_IP'}[0];
	    #warn  $maild;

	    my $verdict = $akismet->check(
		USER_IP                 => $srcip,
		COMMENT_USER_AGENT      => 'Mozilla/5.0',
		COMMENT_CONTENT         => $maild,
		COMMENT_AUTHOR          => $author,
		COMMENT_AUTHOR_EMAIL    => $email,
		COMMENT_AUTHOR_URL    => $curl,
		REFERRER                => $curl,
		) or die('Is the server here?');

	    my $w = 128;
	    $maild =~ s/\n/ /g;
	    my $report = $email . ":". substr($maild,0,$w);
	    
	    if ('true' eq $verdict){
		warn "SPAM: " . $report;
	    }
	    else
	    {
		warn "NOTSPAM: " . $report;
	    }

	}
    }
}
