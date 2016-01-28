#!/bin/bash
#
# chk_lastvalue.sh
#
# last update: 2015/12/14 15:30
#

FLG=$1
if [ $# -ne 1 ];then
        echo "set [before] or [after]"
        exit 0
fi

### ENV_SG
SEC_LASTCLOCK_UPDATECHECK=600   # lastclock更新チェック比較時間（秒）
HEADER_NAME_HOSTNAME="hostname"
HEADER_NAME_ITEMNAME="itemname"
HEADER_NAME_LASTCLOCK="lastclock(timestamp)"
HEADER_NAME_STATUS="status"
INDX_HOSTNAME=2
INDX_ITEMNAME=4
INDX_LASTCLOCK=7
INDX_STATUS=8
FILE_ALL=${FLG}_all.txt
FILE_EXCLUDE=${FLG}_exclude.txt
FILE_STATUS_1=${FLG}_status1.txt
FILE_OK=${FLG}_OK.txt
FILE_NG_ALL=${FLG}_NG_all.txt
FILE_NG_HOST_ALL=${FLG}_NG_HOST_all.txt
FILE_NG_ST=${FLG}_NG_storage.txt
FILE_NG_BMC=${FLG}_NG_bmc.txt
FILE_NG_ESX=${FLG}_NG_esx.txt
FILE_NG_OTHERS=${FLG}_NG_others.txt

### Function
init() {
  \rm -rf ${FLG}*
}

get_item_lastvalue() {
  export PYTHONPATH=/etc/zabbix/zabi_cloud/zabbix
  /usr/bin/python /etc/zabbix/zabi_cloud/zabbix/tools/get_item_lastvalue.py
}

get_index_of_array() {
  _key=$1; shift
  _array=($@)
  for i in `seq 1 ${#_array[@]}`; do
    [ ${_array[i-1]} == ${_key} ] && echo $i
  done
}

### Main
init
COUNT_ITEM=0
ROW=0
BEFORE_HOST=""
get_item_lastvalue | while read -r _line; do
  # get_item_lastvalue結果の行番号
  ((ROW++))

  # 取得不可と判断する基準日時
  ### lastclock が $UNIXTIME より前だったら取得不可とする
  ### UNIXTIME=現在日時-600sec（${SEC_LASTCLOCK_UPDATECHECK}でtuning可）
  UNIXTIME=$(( `date +%s` - ${SEC_LASTCLOCK_UPDATECHECK} ))

  # 配列変数化
  ### TAB区切りの各カラムを$LINE[n]で取り出せるようにする
  IFS="$(echo -e '\t' )"; LINE=(${_line}); unset IFS

  # ヘッダ情報からカラムのIndex取得
  ### lastclockは何カラム目？っていう情報
  if [ $ROW -eq 2 ]; then
    INDX_HOSTNAME=`get_index_of_array ${HEADER_NAME_HOSTNAME} ${LINE[@]}`
    INDX_ITEMNAME=`get_index_of_array ${HEADER_NAME_ITEMNAME} ${LINE[@]}`
    INDX_LASTCLOCK=`get_index_of_array ${HEADER_NAME_LASTCLOCK} ${LINE[@]}`
    INDX_STATUS=`get_index_of_array ${HEADER_NAME_STATUS} ${LINE[@]}`
    #echo ${LINE[@]}
    #echo $INDX_HOSTNAME $INDX_ITEMNAME $INDX_LASTCLOCK $INDX_STATUS
    continue
  fi

  # ヘッダ＆フッタ除外
  [ ${#LINE[@]} -lt 8 ] && continue

  # 各カラムの比較用変数
  _hostname=${LINE[${INDX_HOSTNAME}-1]}
  _itemname=${LINE[${INDX_ITEMNAME}-1]}
  _lastclock=${LINE[${INDX_LASTCLOCK}-1]}
  _status=${LINE[${INDX_STATUS}-1]}

  # item数カウント
  ### 全itemをファイルに出力
  ((COUNT_ITEM++))
  echo $_line >> ${FILE_ALL}

  # hostname数カウント
  #echo $_hostname ${BEFORE_HOST}
  if [ "$_hostname" != "${BEFORE_HOST}" ]; then
    echo $_hostname
    BEFORE_HOST=$_hostname
  fi

  # LOG/EVENTLOG/snmptrap 除外
  ### 取得不可調査の対象外とし、ファイル出力
  case $_itemname in
    snmptrap?|EVENTLOG*|LOG*|/*|[cC]:*.log)
      echo $_line >> ${FILE_EXCLUDE}
      continue;;
    *)
      ;;
  esac

  # STATUS=1を除外
  ### 取得不可調査の対象外とし、ファイル出力
  if [ $_status -eq  1 ]; then
    echo $_line >> ${FILE_STATUS_1}
    continue
  fi

  # LASTCLOCK更新チェック
  ### チェックOKのものをファイル出力
  if [ $_lastclock -ge ${UNIXTIME} ]; then
    echo $_line >> ${FILE_OK}
    continue
  else
    echo $_line >> ${FILE_NG_ALL}
    grep $_hostname ${FILE_NG_HOST_ALL} >/dev/null 2>&1 || echo $_hostname >> ${FILE_NG_HOST_ALL}
  fi

  # ホスト種別でリストを分ける
  case $_hostname in
    ### Storage
    *ck*pst*|*ck*vst*|*ck*p?sp???|*ck*v?cs???|*ck*psecst*|*ck*plto*)
      echo $_line >> ${FILE_NG_ST}
      ;;
    ### BMC
    *ck*pbsv*|*ck*pmbsv*)
      echo $_line >> ${FILE_NG_BMC}
      ;;
    ### ESX
    *ck*pbhpv*|*ck*pmbhpv*)
      echo $_line >> ${FILE_NG_ESX}
      ;;
    ### Others
    *)
      echo $_line >> ${FILE_NG_OTHERS}
      ;;
  esac

done

### NG_HOSTのソート
sort ${FILE_NG_HOST_ALL} > ${FILE_NG_HOST_ALL}.sorted
