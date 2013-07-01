#! /bin/bash

# Merge SNMPGET OUTPUT

#                                     BASEOID
#                                     |                  SERVICE
#                                     |                  |   RET/MSG
#                                     |                  |   |     STRING 
#                                     |                  |   |     |
#                                     V                  V   V     V
#snmpget -v 2c -c snmp 010.001.001.001 '.1.3.6.1.4.1.15500.9.1.3.1.2."all"'

if [ -z "$4" ]; then
  echo "Faltam argumentos!"
  echo "HOSTADDRESS, SNMP COMMUNITY, SERVICE OID, SEARCH STRING"
  echo ""
  echo "./check_netsnmp.sh 127.0.0.1 snmp_community .9.1 all"
  exit 1;
fi

SNMPGET=`which snmpget`
if [ $? = 1 ]; then
    SNMPGET=`find /servers -name 'snmpget'`
fi

HOST=$1
COMMUNITY=$2

BASEOID=".1.3.6.1.4.1.15500"
SERVICE=$3
  P_MSG_OID=".3.1.2"
  P_RET_OID=".3.1.4"
STRING=$4

OPTS=" -v 2c -c ${COMMUNITY} ${HOST} "

${SNMPGET} ${OPTS} system.sysDescr.0 > /dev/null
ISON=$?

if [ ${ISON} = 1 ]; then
    echo "SNMPGET Timeout"
    exit ${ISON}
fi

# Message Query Output
M=$(""${SNMPGET} ${OPTS} -Ovq ''${BASEOID}${SERVICE}${P_MSG_OID}.\"${STRING}\"''"")
echo ${M}

# Return Code Query Output
R=$(""${SNMPGET} ${OPTS} ''${BASEOID}${SERVICE}${P_RET_OID}.\"${STRING}\"''"")

RET=`echo "${R}" | awk -F': ' '{print $2}'`
exit ${RET}
