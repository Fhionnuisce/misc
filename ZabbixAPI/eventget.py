#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
■実行例
  python eventget.py "2015/9/17 19:00:00" "2015/9/17 19:01:00"

■標準出力
　抽出結果（ＣＳＶ）

2015/09/18 13:00 updated

"""
import os
import sys
import csv
import json
import site
import logging
import datetime
import time
import optparse

reload(sys)
sys.setdefaultencoding('utf-8')

# zabi_cloud のimport
site.addsitedir('/etc/zabbix/zabi_cloud/zabbix/')
from py_lib import initializer


# ログファイル出力設定
cmdName = os.path.basename(__file__)
logLevel = logging.INFO
logFilename = os.path.splitext(cmdName)[0] + '.log'
logFormat = '[%(asctime)s] %(levelname)s %(message)s'
logging.basicConfig(level=logLevel, format=logFormat,
    filename=logFilename, filemode='w')
LOG = logging.getLogger(cmdName)
console = logging.StreamHandler()
console.setLevel(logging.ERROR)
console.setFormatter(logging.Formatter(logFormat))
LOG.addHandler(console)


# 引数のパース処理
def parse_option():
    dt = CustomDatetime.format
    usage = 'usage: %s "%s" "%s"' % (sys.argv[0], dt, dt)
    parser = optparse.OptionParser(usage)
    opts, args = parser.parse_args()
    LOG.info("  --- parse_option() ---")
    LOG.info("  opts: %s, args:%s" % (opts, args))
    if len(args) != 2:
        print parser.print_help()
        sys.exit(0)
    del sys.argv[2:]
    return opts, args[0], args[1]


# CSV出力時にダブルクォート("")をつける設定
class CSVCustomFormat(csv.excel):
    quoting   = csv.QUOTE_ALL


# UNIXTIMEからDateTimeに変換するクラスメソッド
class CustomDatetime(datetime.datetime):
    format = "%Y/%m/%d %H:%M:%S"

    @classmethod
    def unix2date(self, clock):
        return self.fromtimestamp(int(clock)).strftime(self.format)

    @classmethod
    def date2unix(self, stime):
        return int(time.mktime(datetime.datetime.strptime(stime, self.format).timetuple()))


# リストをCSV形式に変換して標準出力する関数
# 日本語変換(UTF-8)も必要
def csv_stdout(arrays):
    w = csv.writer(sys.stdout, CSVCustomFormat())
    utf8_list = [ [ s.encode('utf8') for s in v ]  for v in arrays ]
    w.writerows(utf8_list)


# JSONをソートして標準出力する関数
def sort_json(list):
    print json.dumps(list, sort_keys=True, indent=2), "\n"


# Zabbix-APIクラス
class History(initializer.ZabiCloudInitializer):

    # APIバージョン取得
    def get_api_ver(self):
        return int(getattr(self.zabi, "api_ver", 1))

    # API呼び出し（v1.8, v2.2対応）
    def api_call(self, cmd, parameter):
        api_method = {1: "%s(parameter)" % cmd,
                      2: "api_call('%s', parameter)" % cmd}
        #api_ver = self.get_api_ver()
        api_ver = 2
        LOG.info("  --- api_call() ---")
        LOG.info("  api-ver: %s" % api_ver)
        LOG.info("  self.zabi.zabi_session.%s" % api_method[api_ver])
        LOG.info("  parameter: %s" % parameter)
        try:
            return eval("self.zabi.zabi_session.%s" % api_method[api_ver])
        except Exception as e:
            LOG.error("Zabbix-API is timeout. [%s]" % e)
            sys.exit(1)

    # API: event.get()
    def get_event(self, param):
        return self.api_call("event.get", param)

    # API: alert.get()
    def get_alert(self, param):
        return self.api_call("alert.get", param)

    # alert get for v1.8
    def dxt_alert(self, ut1, ut2):
        api_parameter = {
            "output": ["clock","status","sendto","message"],
            "select_hosts": "extend",
            "sortfield": "clock",
            "sortorder": "DESC",
            "time_from": ut1,
            "time_till": ut2,
            "filter": {"status":"1"}
            }

        res = self.get_alert(api_parameter)

        res2 = []
        for x in res:
            r_clock = CustomDatetime.unix2date(x["clock"])
            r_status = x["status"]
            r_sendto = x["sendto"]
            r_message = x["message"].replace("\n", ",")
            res2.append([r_clock, r_sendto, r_message])

        return res2

    # data ext event for v2.2
    def dxt_event(self, ut1, ut2):
        api_parameter = {
            "output": ["clock","value"],
            "selectHosts": ["host"],
            "selectTriggers": ["description"],
            "select_alerts": ["message", "sendto"],
            "sortfield": "clock",
            "sortorder": "DESC",
            "time_from": ut1,
            "time_till": ut2,
            "filter": {"value":"1"}
            }

        res = self.get_event(api_parameter)

        res2 = []
        for x in res:
            r_clock = CustomDatetime.unix2date(x["clock"])
            r_value = x["value"]
            r_host = x["hosts"][0]["host"]
            r_trigger = x["triggers"][0]["description"]
            _alerts = x["alerts"]
            _alerts = [_alerts] if not isinstance(_alerts, list) else _alerts
            if len(_alerts)!=0:
                r_sendto = _alerts[0]["sendto"]
                r_message = _alerts[0]["message"].replace("\n", ",")
            else:
                r_sendto = ""
                r_message = ""

            #r_sendto = x["alerts"][0]["sendto"]
            #r_message = x["alerts"][0]["message"].replace("\n", ",")
            #res2.append([r_clock, r_host, r_trigger, r_sendto, r_message])
            res2.append([r_clock, r_sendto, r_message])

        return res2

    # v1.8 or v2.2
    def dxt(self, ut1, ut2):
        if self.get_api_ver() == 1:
            res = self.dxt_alert(ut1, ut2)
        else:
            res = self.dxt_event(ut1, ut2)

        return res


# main処理
def main():
    LOG.info("started.")

    opts, dt1, dt2 = parse_option()

    sys.stdout = open('/dev/null', 'w')
    his = History(csAPI=False, logger=LOG)
    sys.stdout = sys.__stdout__

    # main
    ut1 = CustomDatetime.date2unix(dt1)
    ut2 = CustomDatetime.date2unix(dt2)
    #csv_stdout(his.dxt_event(ut1, ut2))
    #csv_stdout(his.dxt_alert(ut1, ut2))
    csv_stdout(his.dxt(ut1, ut2))

    LOG.info("finished successfully.")


if __name__ == '__main__':
    main()

