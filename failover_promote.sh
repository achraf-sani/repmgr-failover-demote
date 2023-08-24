#!/bin/bash
up_id=$1
name=$2
if [[ $name == 'standby_promote' ]] ; then
        declare -A servers
        if [[ $up_id == 1 ]] ; then
                down_id=2
        else
                down_id=1
        fi
        #this array gives the idea of the failed node.eg If id received is 1 the node 2 has failed
        servers[2]="192.168.57.42"
        servers[1]="192.168.57.41"
        while [[ `(ssh -o ConnectTimeout=5 -i /var/lib/postgresql/key.pem vagrant@${servers[$down_id]} echo ok 2>&1)` != 'ok' ]]
        do
                sleep 2
                echo Failed node ${servers[$down_id]} is not reachable >> /var/log/postgresql/repmgr.log
                echo SSH not happening
        done
ssh -T -i <data directory path>/key.pem vagrant@${servers[$down_id]}  << EOF
 sleep 5
 sudo service postgresql stop && sleep 10
 sudo -i -u postgres
 pwd
 rm -rf /var/lib/postgresql/14/main/*
 repmgr --force -h '${servers[$up_id]}' -d repmgr -U repmgr standby clone &&
 exit
 pwd
 sudo service postgresql start && sleep 2
 sudo -i -u postgres
 repmgr standby register -F
EOF
echo ${servers[$up_id]}
fi
