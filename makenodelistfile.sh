#!/bin/bash

. testinclude.sh

OUTFILE=${TESTROOT}/nodelistfile.yaml.temp

echo "create ${OUTFILE}"

echo "# name: 未使用" >${OUTFILE}
echo "# ip: ノードIP" >>${OUTFILE}
echo "# port: ノードポート" >>${OUTFILE}
echo "- " >>${OUTFILE}
echo " nodes:" >>${OUTFILE}

for i in $(seq 10000 $NODEMAX)
do

  echo "  - name: node${i}" >>${OUTFILE}
  echo "    ip: 127.0.0.1" >>${OUTFILE}
  echo "    port: ${i}" >>${OUTFILE}

done

echo "  - name: S" >>${OUTFILE}
echo "    ip: 127.0.0.1" >>${OUTFILE}
