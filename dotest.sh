#!/bin/bash

. testinclude.sh

export SCENARIOFILE=${TESTROOT}/$1
export STARTTIME=$2

if [ $# -ne 2 ]; then
  echo "bad parameter"
  exit 1
fi

cp -p ${SCENARIOFILE} ${DATAROOT}
cp -p testinclude.sh ${DATAROOT}
cp -p domainfile.dat ${DATAROOT}

for i in $(seq 10000 $NODEMAX)
do
  cd ${DATAROOT}/${i}
  ${MAKEUNIFIED2PATH} --batch=0 --port=${i} --template=${TESTROOT}/unified2template.log ${SCENARIOFILE} ${STARTTIME} >makeunified2.log &
  echo $! >makeunified2.pid
  bash ${DATAROOT}/${i}/dobarn &
done
