#!/bin/sh

while read HOST TYPE; do
  LOG=${HOST}_${TYPE}
  echo -e "\n*** $HOST : type$TYPE ***"
  ipmitool -U ckk_adm -P Admin123ckk! -H $HOST fru | tee $LOG
done<<EOL
ck2ejo2-pmbsv053	1.2
ck2ejo2-pmbsv054	V
ck2ejo2-pmbsv055	2.2
ck2ejo2-pbsv0641	3.1
ck2ejo2-pbsv0671	4.1
EOL
