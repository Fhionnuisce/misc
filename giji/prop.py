#!/usr/bin/env python
# -*- coding: utf-8 -*-
import json

iplist = [
    "172.27.189.21",
    "172.27.189.22", "172.27.189.23",
    "172.27.189.31", "172.27.189.32",
    "172.27.189.41", "172.27.189.42",
    "172.27.189.51", "172.27.189.52",
    "172.27.189.101"]
iplist = ["172.27.189.41", "172.27.189.43"]
#iplist = ["172.27.191.23", "172.27.191.101"]
username = "ckk_ibs"
password = "CKK@6002"

from pysphere import VIServer, VIMor, VIProperty, MORTypes, VIApiException
def sort_json(list):
    print json.dumps(list, sort_keys=True, indent=2), "\n"

server = VIServer()

def get_uuid(server, hostkey):
    hmor = VIMor(hostkey, MORTypes.HostSystem)
    prop = VIProperty(server, hmor)
    for item in prop.datastore:
        print item.info.name
        print dir(item.info)

    return prop.hardware.systemInfo.uuid

res = []
for ip in iplist:
    url = "https://%s/sdk" % ip

    print
    print url, username, password
    try:
        server.connect(url, username, password)
        print "login success!"

        hosts = server.get_hosts()

        for k, v in hosts.items():
            print "get_uuid(%s)" % k
            uuid = get_uuid(server, k)
            res.append({"id": k, "host": v, "uuid": uuid})
            sort_json([k, v, uuid])

        server.disconnect()
    except BaseException as e:
        print "login failed! <%s>" % str(e)
