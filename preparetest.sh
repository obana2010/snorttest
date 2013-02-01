#!/bin/bash

. testinclude.sh

export DATESTR=`date "+%Y%m%d-%H%M%S"`

mv ${DATAROOT} ${TESTROOT}/archive/${DATESTR}
#for i in $(seq 10000 $NODEMAX)
#do

  #rm ${DATAROOT}/${i}/barnyard2.conf
  #rm ${DATAROOT}/${i}/nodelistfile.yaml
  #rm ${DATAROOT}/${i}/conffile.yaml
  #rm ${DATAROOT}/${i}/dobarn
  #rm ${DATAROOT}/${i}/makeunified2.log
  #rm ${DATAROOT}/${i}/makeunified2.pid
  #rm ${DATAROOT}/${i}/barnyard2.pid
  #rm ${DATAROOT}/${i}/unified2merged.log.*

  #rmdir "${DATAROOT}/${i}"
#done

for i in $(seq 10000 $NODEMAX)
do
  mkdir -p "${DATAROOT}/${i}"

  cp "${TESTROOT}/barnyard2.conf.temp" "${DATAROOT}/${i}/barnyard2.conf"
  echo "output alert_cu: ktport ${i}, conffile ${DATAROOT}/${i}/conffile.yaml" >>${DATAROOT}/${i}/barnyard2.conf

  cp "${TESTROOT}/nodelistfile.yaml.temp" "${DATAROOT}/${i}/nodelistfile.yaml"
  echo "    port: $i" >>${DATAROOT}/${i}/nodelistfile.yaml

  # parameter
  #cp ${TESTROOT}/conffile.yaml.temp ${DATAROOT}/${i}/conffile.yaml
  #echo "  - $i" >>${DATAROOT}/${i}/conffile.yaml
  sed -e "s/@1/$i/g" ${TESTROOT}/conffile.yaml.temp >${TESTROOT}/conffile.yaml.temp.1
  sed -e "s/@2/$TIMESLOTSIZE/g" ${TESTROOT}/conffile.yaml.temp.1 >${DATAROOT}/${i}/conffile.yaml
  rm ${TESTROOT}/conffile.yaml.temp.1

  echo "#!/bin/sh" >${DATAROOT}/${i}/dobarn
  echo "export BARNYARD2PATH=\"${BARNYARD2PATH}\"" >>${DATAROOT}/${i}/dobarn
  echo "export DATAROOT=\"${DATAROOT}\"" >>${DATAROOT}/${i}/dobarn
  echo "export PORTNUM=${i}" >>${DATAROOT}/${i}/dobarn
  cat "${TESTROOT}/dobarn.temp" >>${DATAROOT}/${i}/dobarn

done

# theread
echo "  - 50" >>${DATAROOT}/10000/conffile.yaml
for i in $(seq 10001 $NODEMAX)
do
  echo "  - 3" >>${DATAROOT}/${i}/conffile.yaml
done

# make conffiledomain.dat
${TESTROOT}/mergeconffile.pl
for i in $(seq 10000 $NODEMAX)
do
  # domain
  cat ${DATAROOT}/${i}/conffiledomain.dat >>${DATAROOT}/${i}/conffile.yaml
done
