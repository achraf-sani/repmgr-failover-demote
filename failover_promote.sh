#!/bin/bash
up_id=$1
name=$2
if [ $name == 'standby_promote' ] ; then
declare -A servers
if [ $up_id == 1 ] ; then
        down_id=2
else
        down_id=1
fi
#this array gives the idea of the failed node.eg If id received is 1 the node 2 has failed
servers[2]="node2ip or name"
servers[1]="node1ip or name"
while [[ `(ssh -o ConnectTimeout=5 -i <data directory path>/key.pem ubuntu@${servers[$down_id]} echo ok 2>&1)` != 'ok' ]]
do
sleep 2
echo Failed node ${servers[$down_id]} is not reachable >> /var/log/postgresql/repmgr.log
echo SSH not happening
done
ssh -T -i <data directory path>/key.pem ubuntu@${servers[$down_id]}  << EOF
 sleep 5
 sudo service postgresql stop && sleep 10
 sudo -i -u postgres
 pwd
 rm -rf <data directory path>/10/main/*
 repmgr --force -h '${servers[$up_id]}' -d repmgr -U repmgr standby clone &&
 exit
 pwd
 sudo service postgresql start && sleep 2
 sudo -i -u postgres
 repmgr standby register -F
EOF 
echo ${servers[$up_id]}
fi
