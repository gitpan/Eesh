#!perl -w

use strict ;

use Test ;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

my $loaded ;

END {
   print "not ok 1\n" unless $loaded ;
}

use Eesh qw( e_open e_send e_recv ) ;

my @tests ;

sub r {
   my $v = e_recv( @_ ) ;
   return defined $v ? $v : '<undef>' ;
}

my $v ;

BEGIN {

@tests = (

sub {
   $loaded = 1 ;
   ok( 1 ) ;
},

sub { e_open() ; ok( 1 ) ; },

(
   map {
      (
         sub { e_send( 'nop' ) ; ok( 1 ) },
	 sub { ok( r(),        'nop' ) },
	 sub { ok( r( 'nop' ), 'nop' ) },
      )
   } (1..4)
),

sub { my $rs = e_recv( { non_blocking => 1 } ) ; ok( 1 ) },

) ;

plan tests => scalar( @tests ) ;

}

$_->() for ( @tests ) ;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

