#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use XML::Simple;
use Encode qw(decode encode);
use Net::Mollom;
use secrets;

my $mollom = Net::Mollom->new(
    public_key  => $secrets::mollom,
    private_key => $secrets::mollom_p,
    );

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

	    
	    my $l = length($maild);
	    if ($l > 80) {
		$l = 80;
	    }
	    my $title = 'Comment:' .  substr($maild, $l);
		
	    my $check = $mollom->check_content(
		post_title => $title,
		post_body  => $maild,
		);
	    my $w = 128;
	    $maild =~ s/\n/ /g;
	    my $report = $email . ":". substr($maild,0,$w);
	    
	    if ($check->is_spam) {
		warn "SPAM: " . $report;
	    } elsif ($check->is_unsure) {
		warn "MAYBE: " . $report;
	    } elsif ($check->quality < .5) {
		warn "MAYBE2: " . $report;
	    } else  {
		warn "NOTSPAM: " . $report;
	    }

	}
    }
}
