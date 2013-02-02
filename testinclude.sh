#!/bin/bash

. envinclude.sh

export nodecount=200
export nodeinit=10000
export NODEMAX=$(($nodeinit+$nodecount))

# test timeslot size
export TIMESLOTSIZE=10

export timeslot_test_start=0 # always 0
export timeslot_test_end=30

export clients_count=200; # number of clients
export timeslots_client_attack_continue=30; # timeslot count a client continue to attack
export attacks_per_timeslot=1;
export attack_timeslots=1; # a client attack every $attack_timeslots timeslots
export client_random_ratio=50; # randam client percentage

export avg_domainlist_ratio=0.4;
#export avg_domainlist_count=$(($nodecount*$avg_domainlist_ratio)); # 平均ドメイン内ノード数
export domains_count=20; # number of domains

