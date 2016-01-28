#!/bin/bash
#ESXiホストのマクロ登録確認用スクリプト

BASEDIR=$(cd $(dirname $0);pwd)
HOSTLIST_DIR="${BASEDIR}/06_esxi/"
HOSTLIST=$(ls ${HOSTLIST_DIR})

#hostlist編集
HOSTNAME=$(cat ${HOSTLIST_DIR}${HOSTLIST} | sed -e "s/^/'/g" -e "s/$/'/g")
HOSTNAME2=$(echo $HOSTNAME | sed "s/ /,/g")

#hostid取得
HOSTID=$(echo $(mysql -uroot -pPASSW0RD zabbix -N -e "
select hostid from hosts where host in (${HOSTNAME2})
")| sed -e 's/ /,/g')

#各ホストのマクロ出力
mysql -uroot -pPASSW0RD zabbix -e "
select h1.host,hm.macro,hm.value
from hosts h1 left outer join hostmacro hm on h1.hostid=hm.hostid
where h1.hostid in (${HOSTID})
order by h1.host;
"
