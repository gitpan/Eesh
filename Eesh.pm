package Eesh;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
use Carp ;

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw( e_open e_send e_recv );
%EXPORT_TAGS = ( all => \@EXPORT_OK ) ;
$VERSION = '0.11';

bootstrap Eesh $VERSION;

# Preloaded methods go here.

sub e_recv {
   my $options = @_ && ref $_[-1] eq 'HASH' ? pop : {} ;

   my @bad = grep { $_ ne 'non_blocking' } keys %$options ;
   if ( @bad ) {
      my $s = @bad > 1 ? 's' : '' ;
      croak "Unrecognized option$s: " . join( ', ', map { "'$_'" } @bad ) ;
   }

   e_send( $_ ) for ( @_ ) ;

   my $v ;
   my $delay = 1 ;
   while (1) {
      $v = e_recv_nb() ;
      return $v if $options->{non_blocking} || defined $v ;
      select( undef, undef, undef, $delay / 1000 ) ;
      $delay *= 2 if $delay < 50 ;
   }
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Eesh - Perl extension for blah blah blah

=head1 SYNOPSIS

  ## Long form:
  use Eesh qw( e_open e_send e_recv ) ;

  e_open() ;
  e_send( 'window_list' ) ;
  print e_recv() ;

  ## Short form
  use Eesh qw( :all ) ;
  e_open() ;
  print e_recv( 'window_list' ) ;

  ## For non-blocking receives:
  my $hmmm = e_recv( { non_blocking => 1 } ) ;

=head1 DESCRIPTION

Eesh.pm provides very simple wrappers around the routines from eesh.

This code is in alpha mode, please let me know of any improvements,
and patches are especially welcome.

=head2 Functions

=over

=item e_open

Opens communications with E.

=item e_send

Sends to E.

=item e_recv

Receives from E, blocking until data is received.

Can send strings first and then wait for the result:

   my @windows = split( /^/m, e_recv( 'window_list' ) ) ;

Can be called non-blocking:

   e_send( 'window_list' ) ;
    
   my $hmmm ;
   $hmmm = e_recv( { non_blocking => 1 } ) until defined $hmmmm ;

=cut

=back

=head2 Constants

=over

=item E_NB

Passed to e_recv() to make it non blocking

=cut

=back

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 SEE ALSO

eesh

=cut
