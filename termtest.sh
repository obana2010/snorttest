#!/bin/bash

. testinclude.sh

for i in $(seq 10000 $NODEMAX)
do

  cd ${DATAROOT}/${i}

  [ -f makeunified2.pid ] && kill `cat makeunified2.pid` && rm makeunified2.pid
  [ -f barnyard2.pid ] && kill `cat barnyard2.pid` && rm barnyard2.pid

done
