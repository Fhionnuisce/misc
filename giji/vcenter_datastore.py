from pysphere import VIServer, VIProperty 

# vCenter IPaddress
ip = "172.27.189.101"
url = "https://%s/sdk" % ip
username = "ckk_ibs"
password = "CKK@6002"

server = VIServer() 
server.connect(url, username, password) 

for ds_mor, hostname in server.get_hosts().items(): 
    print
    print "***", ds_mor, hostname

    props = VIProperty(server, ds_mor) 
    for item in props.datastore:
        print item.info.name

server.disconnect() 
