#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use XML::Simple;
use Mail::SpamAssassin;
use MIME::Lite;
use Mail::SpamAssassin::Message;
use Encode qw(decode encode);

my $file= shift;
my $xs = XML::Simple->new();
my $ref = $xs->XMLin($file, ForceArray => 1, KeyAttr => []);
my $posts = $ref->{channel}[0]->{item};
my $PREFIX          = '/usr';             # substituted at 'make' time
my $DEF_RULES_DIR   = '/usr/share/spamassassin';      # substituted at 'make' time
my $LOCAL_RULES_DIR = '/etc/mail/spamassassin';    # substituted at 'make' time
my $LOCAL_STATE_DIR = '/var/lib/spamassassin';    # substituted at 'make' time

my %setup_args = (
    dont_copy_prefs      => 0,
    force_ipv4           => 0,
    local_tests_only     => 0,
    debug                => 1,
    paranoid             => 1,
    require_rules        => 1,
    skip_prng_reseeding  => 1,  # let us do the reseeding by ourselves
    PREFIX          => $PREFIX,
    DEF_RULES_DIR   => $DEF_RULES_DIR,
    LOCAL_RULES_DIR => $LOCAL_RULES_DIR,
    LOCAL_STATE_DIR => $LOCAL_STATE_DIR   
);

binmode STDOUT, ":utf8";

my $sa = Mail::SpamAssassin->new(\%setup_args);
$sa->init(); # parse rules

foreach my $post (@{$posts}) {
    if ($post->{'wp:post_type'}[0] =~ /^post|page$/) {
	
	warn  $post->{'title'}[0];
	
	for my $comment (@{ $post->{'wp:comment'}}) {
	    my $maild = $comment->{'wp:comment_content'}[0];
	    my $email = $comment->{'wp:comment_author_email'}[0];
	    my $curl = $comment->{'wp:comment_author_url'}[0];
	    my $srcip = $comment->{'wp:comment_author_IP'}[0];
	    #warn  $maild;


	    my $mmsg = MIME::Lite::->new(
		'To'      => 'comments@pirate-party.com',
		'From'    => $email,
		'Subject' => 'Comment:' .  substr(40,$maild),
		'Type' => "text/plain",
		'Data' => $maild . " URL: ".  $curl,	       
		);

	    
	    $mmsg->add("Received" => [ $srcip ]);
	    my $str = $mmsg->as_string();
	    #warn $str;
	    my $octets     = encode('UTF-8', $str, Encode::FB_CROAK);
	    
	    my $mail = Mail::SpamAssassin::Message->new(
		{
		    'message' => $octets, 
		    'parsenow' => 1, 
		    'normalize' => 0, 
		}
		);
	    
	    my $msg = Mail::SpamAssassin::PerMsgStatus->new($sa,  $mail );

	    $msg->check();

	    my $w = 128;

	    $maild =~ s/\n/ /g;
	    if ($msg->is_spam()){
		warn "SPAM: " . substr($maild,0,$w);
	    }
	    else
	    {
		warn "NOTSPAM: " . substr($maild,0,$w);
	    }

	}
    }
}
