#!/bin/sh

while read host; do
  echo -e "\n### $host ###"
  nslookup $host
  echo -e "\n--- Ping ----"
  ping -c1 $host
  echo -e "\n--- IPMI ----"
  ipmitool -U bmcipmi -P Zbx1PM1pw -H $host sel
  echo -e "\n--- SNMPget -"
  snmpget -v2c -c public $host  1.3.6.1.4.1.7244.1.2.1.3.5.1.4.16
  echo "#############"
done<<EOL
ck2ejo2-pmbsv054
ck2ejo2-pmbsv058
ck2ejo2-pmbsv060
ck2ejo2-pmbsv072
ck2ejo2-pmbsv073
EOL
