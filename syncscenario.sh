#!/bin/sh

rm upload.tgz
tar cvzf upload.tgz testinclude.sh scenario.csv domainfile.dat nodelistfile.yaml.temp
git add upload.tgz
git commit -m "syncscenario"
git push
