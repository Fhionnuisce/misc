#iplist = ["172.27.189.23", "172.27.189.101"]
iplist = ["172.27.189.40", "172.27.189.41", "172.27.189.43"]
username = "ckk_ibs"
password = "CKK@6002"

from pysphere import VIServer

server = VIServer()

for ip in iplist:
    url = "https://%s/sdk" % ip

    print
    print url, username, password
    try:
        server.connect(url, username, password)
        print "login success!"
        server.disconnect()
    except BaseException as e:
        print "login failed! <%s>" % str(e)
