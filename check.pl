#!/usr/bin/env perl
#===============================================================================
#
#         FILE: check.pl
#
#        USAGE: ./check.pl ticket-number
#
#
#       AUTHOR: Freek Kalter
#      VERSION: 0.1
#      CREATED: 10/10/2012 08:45:44 PM
#===============================================================================

use v5.14;
use utf8;

use HTML::TreeBuilder;
use LWP;
use Encode;
use Data::Dumper;
use Term::ANSIColor;

binmode(STDOUT, ":utf8");

chomp( my $number = uc($ARGV[1] ? "$ARGV[0]$ARGV[1]" : $ARGV[0] ));
if( $number !~ m/^[A-Za-z]{2} ?[0-9]{6}$/ ){
    die "Usage: check.pl CI005406";
}

my @number = split('', $number);

my $url = "https://www.staatsloterij.nl/trekkingsuitslag";
my $content = decode_utf8( do_GET($url) );
my $root = HTML::TreeBuilder->new;
$root->parse($content);

my @prizes =();
my $prize = 0;
my $matched ="";
for my $tr ( $root->find_by_attribute( "class" , "nr$number[-1]" )->look_down( "_tag", "tr" ) ){
    for my $td ($tr->find_by_tag_name("td")){
        if($td->attr("class") eq "hCol2"){
            my ($let, $num) = $td->as_text =~ m/([A-Z]{0,2})\s+([0-9]{1,6})/;
            if( $number =~ /$let$num$/ ){
                my ($money) = $td->right()->as_text =~ m/([0-9.,]+)/;
                $money =~ s/[.,]//g;
                if(  $money > $prize ) { $prize = $money; $matched="$let$num"; } ;
            }
        }
    }
}
if($prize > 0){
    print substr $number, 0, length($matched)* -1;
    say colored($matched, 'red bold');

    $prize =~ s/(.*)([0-9]{2})$/$1,$2/; # add , on right place
    1 while $prize =~ s/(\d)(\d\d\d)(?!\d)/$1.$2/; # add . on right places
    say "Won: €$prize";
}else{
    say "No prizes.";
}

sub do_GET {
    my $browser;
    $browser = LWP::UserAgent->new unless $browser;
    my $resp = $browser->get(@_);
    return ( $resp->content, $resp->status_line, $resp->is_success, $resp )
      if wantarray;
    return unless $resp->is_success;
    return $resp->content;
}

