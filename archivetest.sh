#!/bin/bash

. testinclude.sh

export DATESTR=`date "+%Y%m%d-%H%M%S"`

mv ${DATAROOT} ${TESTROOT}/archive/${DATESTR}
echo ${DATESTR}
