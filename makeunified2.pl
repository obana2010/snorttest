#!/usr/bin/perl

# usage
# makeunified2.pl scenariofile.csv 23:59
# makeunified2.pl scenariofile.csv 09:09

use strict;
use warnings;
use Data::Dumper;
use Socket;
use Time::Piece ();
use Time::HiRes qw/usleep/;

use IO::Handle;
STDOUT->autoflush(1);

my $slotsize = $ENV{'TIMESLOTSIZE'} - 0;

my $length_Unified2Packet = 28;
my $length_EternetHeader = 14;

my $batchmode = 0;
use App::Options(
    option => {
        batch  => "type=boolean; default=false;",
        port  => "type=integer; required;",
        template  => "type=string; required;",
    },
);

sub main {

    if (@_ < 1) {
        die "invalied arguments.\n";
    }

    my ($unified2_file) = $App::options{template};
    #my ($unified2_file) = "unified2template.log";
    my ($scenario_file, $startrealtime) = @_;

    if ($App::options{batch}) {
        print "batch mode.\n";
        $batchmode = 1;
    }

    my $ktport = $App::options{port};
    print STDERR "++++ makeunified2 start [$ktport]\n";

    # check start time
    my $time = Time::Piece::localtime();
    my $test_start_time = Time::Piece->strptime($time->ymd . ' ' . $startrealtime . ':00', '%Y-%m-%d %H:%M:%S');
    my $diffsec = $test_start_time->epoch - $time->epoch - (60 * 60 * 9); # JST
    if (!$batchmode && ($diffsec < 0 || 600 < $diffsec)) {
        print $test_start_time->datetime . " - " . $time->datetime . "\n";
        die("bad start time. [$diffsec]");
    }

    # timeslot of test start time
    my $timeslot_test_starttime = $test_start_time->epoch / $slotsize;

    open(my $ofp, ">", "unified2merged.log.999");
    binmode($ofp);

    my $recordcount = 1;
    my $buf_header;

    my ($timeslot_current, $target_ip, $target_port, $client_ip, $target_name);

    my $microsec = 0; # microsec for timestamp
    open(my $sfp, "<", $scenario_file) or die "Cannot open $scenario_file: $!";
    while(my $line = readline $sfp) {

        chomp $line;
        ($timeslot_current, $target_ip, $target_port, $client_ip, $target_name) = split(/,/, $line);
#print $timeslot_current;print "\n";

        if ($ktport != $target_port) {
            print "Skip record. port [$target_port]\n";
            next;
        }

        $timeslot_current += $timeslot_test_starttime;
#print $timeslot_current;print "\n";

        # timeslot wait
        my $time;
        while (1) {
            $time = Time::Piece::localtime();
            my $timeslot_localtime = ($time->epoch + (60 * 60 * 9)) / $slotsize; # JST?
            #my $timeslot_localtime = ($time->epoch) / $slotsize; # JST?
            if (!$batchmode && ($timeslot_localtime < $timeslot_current)) {
                #sleep(1);
                usleep(100000); # 0.1 sec
                print "[$timeslot_localtime] [$timeslot_current]\n";
                next;
            } else {
                # start!
                print "\n";
                sleep(4); # drift from barnyard2
                last;
            }
        }

        open(my $ifp, "<${unified2_file}");
        binmode($ifp);

        my $out;

        my $count = 0;
        while (1) {

            # **** header Unified2RecordHeader 8バイト
            my $bytes_read = read($ifp, $buf_header, 8);
            if ($bytes_read != 8){
                printf("read error $! [%d]\n", __LINE__);
                exit;
            }

            my @xx = unpack("NN", $buf_header);
            my $type = $xx[0];
            my $length = $xx[1];
            printf("Header: Type=%u (%u bytes)\n", $type, $length);

            print $ofp ($buf_header);

            if (104 == $type) {

if (0) {
                $bytes_read = read($ifp, $buf_header, $length);
                if ($bytes_read != $length){
                    printf("read error [%d]\n", __LINE__);
                    exit;
                }
                print $ofp ($buf_header);
} else {

                my $already_read = 0; # already read bytes
                $bytes_read = read($ifp, $buf_header, 8);
                $already_read += 8;
                print $ofp ($buf_header);

                $bytes_read = read($ifp, $buf_header, 8);
                $already_read += 8;

                # epoch sec
                $out = pack("i", ($timeslot_current * $slotsize) - (60 * 60 * 9)); # timeslot => epoch
                print $ofp ($out);

                # microsec
                #$out = pack("i", 0);
                $out = pack("i", $microsec++);
                # counter stop check
                if ((1000 * 1000) == $microsec) {
                    $microsec = 0;
                }
                print $ofp ($out);

                $bytes_read = read($ifp, $buf_header, $length - $already_read);
                print $ofp ($buf_header);

}
            } elsif (2 == $type) {
 
 if (1){
               # Unified2Packet
                $bytes_read = read($ifp, $buf_header, $length_Unified2Packet);
                if ($bytes_read != $length_Unified2Packet){
                    printf("read error [%d]\n", __LINE__);
                    exit;
                }
                print $ofp ($buf_header);
}
if (0){
                # Unified2Packet before event_second
                $bytes_read = read($ifp, $buf_header, 8);
                if ($bytes_read != 8){
                    printf("read error [%d]\n", __LINE__);
                    exit;
                }
                print $ofp ($buf_header);

                # event_second
                $bytes_read = read($ifp, $buf_header, 4);
                if ($bytes_read != 4){
                    printf("read error [%d]\n", __LINE__);
                    exit;
                }
                #print $ofp ($buf_header);
                #my $null = "\0\0\0\0";
                #print $ofp ($null);

                # packet_second
                $bytes_read = read($ifp, $buf_header, 4);
                if ($bytes_read != 4){
                    printf("read error [%d]\n", __LINE__);
                    exit;
                }
                # packet_microsecond
                $bytes_read = read($ifp, $buf_header, 4);
                if ($bytes_read != 4){
                    printf("read error [%d]\n", __LINE__);
                    exit;
                }

                $out = pack("i", $time->epoch);
#                $out = pack("i", 0);
                print $ofp ($out); # event_second
                $out = pack("i", $time->epoch);
#                $out = pack("i", 0);
                print $ofp ($out); # packet_second
                $out = pack("i", 0);
                print $ofp ($out); # packet_microsecond

                # Unified2Packet after event_second
                $bytes_read = read($ifp, $buf_header, ($length_Unified2Packet - 8 - 4 - 4 - 4));
                if ($bytes_read != ($length_Unified2Packet - 8 - 4 - 4 - 4)){
                    printf("read error [%d]\n", __LINE__);
                    exit;
                }
                print $ofp ($buf_header);
}
                # EthernetHeader
                $bytes_read = read($ifp, $buf_header, $length_EternetHeader);
                if ($bytes_read != $length_EternetHeader){
                    printf("read error [%d]\n", __LINE__);
                    exit;
                }
                print $ofp ($buf_header);

                # IP Header before ip
                $bytes_read = read($ifp, $buf_header, 12);
                if ($bytes_read != 12){
                    printf("read error [%d]\n", __LINE__);
                    exit;
                }
                print $ofp ($buf_header);

                # src ip
                my $ip_src_long = inet_aton($client_ip);
                print $ofp ($ip_src_long);
                # dst ip
                my $ip_dst_long = inet_aton($target_ip);
                print $ofp ($ip_dst_long);

                # src port
                $out = pack("n", 9999);
                print $ofp ($out);
                # dst port
                $out = pack("n", $target_port);
                print $ofp ($out);

                # skip
                $bytes_read = read($ifp, $buf_header, 12);
                if ($bytes_read != 12){
                    printf("read error [%d]\n", __LINE__);
                    exit;
                }

                # remain data
                my $remain =  $length - $length_Unified2Packet - $length_EternetHeader - 12 - 12;
                $bytes_read = read($ifp, $buf_header, $remain);
                if ($bytes_read != $remain){
                    printf("read error [%d]\n", __LINE__);
                    exit;
                }
                print $ofp ($buf_header);

            } else {

                # other
                $bytes_read = read($ifp, $buf_header, $length);
                if ($bytes_read != $length){
                    printf("read error [%d]\n", __LINE__);
                    exit;
                }
                print $ofp ($buf_header);

            }

            if (++$count == 2) {
                last;
            }

        } # record

        close($ifp);
    } # rows

    print STDERR "++++ makeunified2 exit [$ktport]\n";
}

main(@ARGV);
