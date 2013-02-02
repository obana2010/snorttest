#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use YAML::XS;
use Time::Piece();
#use Time::HiRes;
#my $start_time = Time::HiRes::time;
use App::Options(
    option => {
        scenariofile  => "type=string; required; default=scenario.csv;",
        nodefile  => "type=string; required; default=nodelistfile.yaml.temp;",
        domainfile  => "type=string; required; default=domainfile.dat;",
    },
);

# test
my $timeslot_test_start = $ENV{'timeslot_test_start'} - 0; # always 0
my $timeslot_test_end = $ENV{'timeslot_test_end'} - 0;
#my $timeslot_test_start = 0; # always 0
#my $timeslot_test_end = 30;
my $timeslot_count = $timeslot_test_end - $timeslot_test_start;

# clients
my @clients;
my $clients_count = $ENV{'clients_count'} - 0; # number of clients
my $timeslots_client_attack_continue = $ENV{'timeslots_client_attack_continue'} - 0; # timeslot count a client continue to attack
my $attacks_per_timeslot = $ENV{'attacks_per_timeslot'} - 0;
my $attack_timeslots = $ENV{'attack_timeslots'} - 0; # a client attack every $attack_timeslots timeslots
my $client_random_ratio = $ENV{'client_random_ratio'} - 0; # randam client percentage
#my $clients_count = 100; # number of clients
#my $timeslots_client_attack_continue = 3; # timeslot count a client continue to attack
#my $attacks_per_timeslot = 3;
#my $attack_timeslots = 1; # a client attack every $attack_timeslots timeslots
#my $client_random_ratio = 50; # randam client percentage

# CDIN
my @cidnnodes;
my %domains;

# domain
#my $avg_features_count = 3; # 平均特徴数
my $avg_domainlist_ratio = $ENV{'avg_domainlist_ratio'} - 0;
my $avg_domainlist_count = $avg_domainlist_ratio * $ENV{'nodecount'}; # 平均ドメイン内ノード数
my $domains_count = $ENV{'domains_count'} - 0; # number of domains

#print "$timeslot_test_start\n"; # always 0
#print "$timeslot_test_end\n";
#print "$clients_count\n"; # number of clients
#print "$timeslots_client_attack_continue\n"; # timeslot count a client continue to attack
#print "$attacks_per_timeslot\n";
#print "$attack_timeslots\n";
#print "$client_random_ratio\n";
#print "$avg_domainlist_ratio\n";
#print "$avg_domainlist_count\n";
#print "$domains_count\n";

sub main() {

  ##############################################
  # open output files
  my $scenariofile = $App::options{scenariofile};
  open(my $ofp, ">", $scenariofile) or die;

  my $domainfile = $App::options{domainfile};
  open(my $ofp_domain, ">", $domainfile) or die;

  ##############################################
  # make nodelistfile
  system("./makenodelistfile.sh");

  ##############################################
  # load nodes
  my $nodefile = $App::options{nodefile};
  my $yml = YAML::XS::LoadFile($nodefile);

  foreach my $nodeconf (@$yml) {
    foreach my $nodeconfkey (keys %$nodeconf) {
      if ("nodes" eq $nodeconfkey) {
        my $nodelines = $$nodeconf{nodes};
        foreach my $nodeline (@$nodelines) {
#print Dumper(%$nodeline);
          # skip
          if ("S" eq $nodeline->{name}) {
            next;
          }
          # skip server node
          if ("10000" eq $nodeline->{port}) {
            next;
          }
          my @domains;
          my %node = (
                      name => $nodeline->{name},
                      ip => $nodeline->{ip},
                      port => $nodeline->{port},
                      domains => \@domains,
                      );
          push(@cidnnodes, \%node);
        }
      }
    }
  }

  ##############################################
  # make domains

  # check domain size
  if (($#cidnnodes + 1 ) < $avg_domainlist_count) {
    die "nodelist is too small\n"
  }

  # make all
  my %domain = ();
  foreach my $node (@cidnnodes) {
    # generate key
    my $key = sprintf("%s:%s", $node->{ip}, $node->{port});
    $domain{$key} = $node;
  }
  $domains{"domainall"} = \%domain;

  # domains loop
  for (my $i = 0; $i < $domains_count; $i++) {

    my %domain = ();

    # node in domain loop
    my $domainname = sprintf("domain%03d", ${i});
    for (my $j = 0; $j < $avg_domainlist_count; $j++) {
      while (1) {
        # get node
        my $node = $cidnnodes[int(rand($#cidnnodes + 1))];
        # generate key
        my $key = sprintf("%s:%s", $node->{ip}, $node->{port});
#print "$key\n";
        # check
        if (defined($domain{$key})) {
          next;
        }
        $domain{$key} = $node;
        my $domains_ref = $node->{domains};
        push(@$domains_ref, $domainname);
#print Dumper(@$domains_ref);
        last;
      }
    }
    $domains{$domainname} = \%domain;
#print Dumper(%domain);
#print "********\n";
  }

#print Dumper(%domains);
#print Dumper(@cidnnodes);

  # domain file
  foreach my $node (@cidnnodes) {
    my $domains_ref = $node->{domains};
    my $key = $node->{ip} . ':' . $node->{port};

    print $ofp_domain "[$key]\n";
    print $ofp_domain "- \n";
    print $ofp_domain " features: \n";

    foreach my $domainname (@$domains_ref) {
      print $ofp_domain "  - $domainname\n";
    }
  }

  ##############################################
  # make clients
  for (my $i = 0; $i < $clients_count; $i++) {

    # start and end
    my $timeslot_client_start = int(rand($timeslot_count));
    my $timeslot_client_end = $timeslot_client_start + $timeslots_client_attack_continue - 1;
#    # cut after test end
#    if ($timeslot_test_end < $timeslot_client_end) {
#      $timeslot_client_end = $timeslot_test_end
#    }

    # pickup target domain
    my $target_domain_name;
#    if (int(rand(100 + 1)) <= $client_random_ratio) {
    if ($i < ($clients_count * $client_random_ratio / 100)) {

      # random target
      #print "random\n";
      $target_domain_name = "domainall";
    } else {
      # fixed target
      #print "not random\n";
      my $domainno = int(rand($domains_count));
      $target_domain_name = sprintf("domain%03d", $domainno);;
    }

    my $oct4 = $i % 256;
    my $oct3 = int($i / 256);

    my %client = (
              target_domain_name => $target_domain_name, #target domain name
              ip => "100.100.$oct3.$oct4", # MAX is 65535
              attackperiod => 100, # attack continue time
              timeslot_client_start => $timeslot_client_start,
              timeslot_client_end => $timeslot_client_end,
              attacks_per_timeslot => $attacks_per_timeslot,
              attacked => 0,
              #attacked_node => (),
              );
    push(@clients, \%client);

    print "client [${target_domain_name}] start [${timeslot_client_start}] end [${timeslot_client_end}]\n";
  }

  ##############################################
  # timeslot loop
  my $existattacker = 0;
  #for (my $timeslot_current = $timeslot_test_start; $timeslot_current < $timeslot_test_end; $timeslot_current++) {
  for (my $timeslot_current = $timeslot_test_start; ; $timeslot_current++) {

    $existattacker = 0;

    # client loop
    foreach my $client (@clients) {

      # attack period ?
      if (($client->{timeslot_client_start} <= $timeslot_current) &&
          ($timeslot_current <= $client->{timeslot_client_end})) {

        # there are attackers
        $existattacker = 1;

          # attack timeslot ?
        if (0 == (($timeslot_current + $client->{timeslot_client_start}) % $attack_timeslots)) {

          # get target domain
          my $target_domain_name = $client->{target_domain_name};
#print "$target_domain_name\n";
          my $target_domain = $domains{$target_domain_name};
#print Dumper($target_domain);

          my @target_domain_keys = keys %$target_domain;
#print Dumper(@target_domain_keys);
          my $count_domain_nodes = $#target_domain_keys + 1;
#print "$count_domain_nodes\n";

          # attack loop
          for (my $attack_count = 0; $attack_count < $client->{attacks_per_timeslot}; $attack_count++) {

            # pickup target node
            my $index = int(rand($count_domain_nodes));
#print "$index\n";
            my $key_node = $target_domain_keys[$index];
#print "$key_node\n";
            my $target_node = $target_domain->{$key_node};
#print Dumper($target_node);
            #my $target_node = $$target_domain[int(rand($count_node_domain + 1))];
            my $target_ip = $target_node->{ip};
            my $target_port = $$target_node{port};
            my $client_ip = $client->{ip};

            # random client attacks only once.
            if ("domainall" ne $target_domain_name || 0 == $client->{attacked}) {
              $client->{attacked} = 1;
              printf $ofp "%d,%s,%s,%s,%s\n", $timeslot_current, $target_ip, $target_port, $client_ip, $target_domain_name;
            }
#            print Dumper($target_node);

          } # attack loop

        } # not attack timeslot

#print $count_node_domain;
      } # target domain
    } # client

    # no attacker and exceeded end timeslot?
    if ((0 == $existattacker) && ($timeslot_test_end < $timeslot_current)) {
      last;
    }
  } # timeslot

  close($ofp);
  close($ofp_domain);
}

main();
exit();
