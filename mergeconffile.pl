#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use App::Options(
    option => {
        domainfile  => "type=string; required; default=domainfile.dat;",
    },
);

sub main() {

  ##############################################
  my $idomainfile = $App::options{domainfile};
  open(my $ifp_domain, "<", $idomainfile) or die;

  ##############################################
  # load domains
  my $ofp_domain;
  while (my $line = readline $ifp_domain) {
#print $line;
    if ($line =~ /\[(\d+)\.(\d+)\.(\d+)\.(\d+):(\d+)\]/) {
#print $5;
      # output file close
      if ($ofp_domain) {
        close($ofp_domain);
      }
      # output file open
      my $odomainfile = $ENV{'DATAROOT'} . "/${5}/conffiledomain.dat";
#print "write $odomainfile\n";
      open($ofp_domain, ">", $odomainfile) or die "cannot open[$odomainfile]";
    } else {
      print $ofp_domain $line;
    }
  }

  close($ofp_domain);
  close($ifp_domain);
}

main();
exit();
