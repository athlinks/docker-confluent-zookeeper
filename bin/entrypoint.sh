#!/bin/bash

mkdir -p /tmp/zookeeper
echo ${MYID:-1} > /tmp/zookeeper/myid

MYIP="$(ip -o -4 addr list eth0 | grep global | awk '{print $4}' | cut -d/ -f1)"


echo "tickTime=2000" >> /opt/confluent/etc/kafka/zookeeper.properties
echo "dataDir=/tmp/zookeeper" >> /opt/confluent/etc/kafka/zookeeper.properties
echo "clientPort=2181" >> /opt/confluent/etc/kafka/zookeeper.properties



if [[ !  -z  $OTHER_NODES  ]]; then
  echo "initLimit=10" >> /opt/confluent/etc/kafka/zookeeper.properties
  echo "syncLimit=5" >> /opt/confluent/etc/kafka/zookeeper.properties
  echo "ConnectPort=2888" >> /opt/confluent/etc/kafka/zookeeper.properties
  echo "ElectionPort=3888" >> /opt/confluent/etc/kafka/zookeeper.properties

  IFS=',' read -r -a ARRAY <<< "$OTHER_NODES"
  NODENUM=$((${#ARRAY[@]}))

  echo "$NODENUM NODE CLUSTER"
  echo "NODES: ME($MYIP),$OTHER_NODES"

  COUNT=0
  REMOTECOUNT=0
  echo "server.$MYID=$MYIP:2888:3888" >> /opt/confluent/etc/kafka/zookeeper.properties
  while [[ $COUNT -lt $NODENUM ]]; do
    NODE=${ARRAY[$COUNT]}
    IFS='=' read -r -a FIELDS <<< "$NODE"
    NODEID=${FIELDS[0]}
    REMOTEADDR=${FIELDS[1]}
    echo "NODE=$NODE; FIELDS=${FIELDS[@]}; NODEID=$NODEID; REMOTEADDR=$REMOTEADDR;"
    echo "server.$NODEID=$REMOTEADDR:2888:3888" >> /opt/confluent/etc/kafka/zookeeper.properties
    ((COUNT++))
  done
else
  echo "STANDALONE CLUSTER - YOU ARE DOING SOMETHING VERY WRONG!"
fi

echo
echo "### GENERATED CONFIG ###"
echo "/opt/confluent/etc/kafka/zookeeper.properties"
cat /opt/confluent/etc/kafka/zookeeper.properties
echo "########################"
echo



# server.1=...
#if [ -n "$SERVERS" ]; then
#    python -c "print '\n'.join(['server.%i=%s:2888:3888' % (i + 2, x) for i, x in enumerate('$SERVERS'.split(','))])" >> /opt/zookeeper/conf/zoo.cfg
#fi


sleep 2
exec "$@"
