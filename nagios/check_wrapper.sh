#! /bin/bash
# Script to wrap commands
# Version: 0.2
# Date: 05 September 2012 - <francisco.cabrita@gmail.com>

# NSCA OUTPUT FORMAT
#   HOSTNAME\tNSCA_PASSIVECHECK_DESC\tRETURNCODE\tSTATUS:MSG
#
# Example
#   sql-cl01  Passive Check SSH   0   OK:Passive Check SSH
#   sql-cl01  Passive Check SSH   2   CRITICAL:Passive Check SSH

DATE="$(date "+%Y-%m-%d_%H:%M")"
LOGFILE="/tmp/temp-${DATE}.log"

E_BADARGS=65

CMDARGS=$*
ACTION=$1
NUMARGS=$#

OLDPATH=$PATH

# Load current pwd to PATH. type command will not fail this way.
export PATH=`pwd`:$PATH

# Restore original PATH
function restorepath () {
    export PATH=$OLDPATH
}

NAGIOS_HOST="nagiosserver"

# NAGIOS return codes
NORM=0
WARN=1
CRIT=2
UNKN=3

# Standard return codes for Linux
# 255 exit status out of range
# 127 command not found
# 77 permission denied
# 64 command line usage error
# 0 ok

ECHO=`which echo`

SEND_NSCA=`which send_nsca`
SEND_NSCA_CFG=`find /etc -name 'send_nsca.cfg'`
if [ "${SEND_NSCA_CFG}" = "" ]; then
   SEND_NSCA_CFG=`find /usr/local/etc -name 'send_nsca.cfg'`
fi

AS_FACTER="TRUE"

# VERIFY FACTER PATH
if [ -f /servers/puppet/bin/facter ]; then
    NIX="DEBIAN"
    FACTER="/servers/puppet/bin/facter"
elif [ -f /usr/bin/facter ]; then
    NIX="REDHAT"
    FACTER="/usr/bin/facter"
elif [ -f /usr/local/bin/facter ]; then
    NIX="BSD"
    FACTER="/usr/local/bin/facter"
else
    NIX="UNKNOWN"
    FACTER=`which facter`
    AS_FACTER="FALSE"
fi

# FETCH HOSTNAME THROUGH FACTER
if [ "${AS_FACTER}" = "TRUE" ]; then
    FACT_HOSTNAME=`${FACTER} hostname`
    FACT_KERNEL=`${FACTER} kernel`
    FACT_FQDN=`${FACTER} fqdn`
    FACT_OS=`${FACTER} operatingsystem`
fi

HOSTNAME=`hostname -s`

# well, you know...
function myhelp {
    echo ""
    echo "Usage:"
    echo "check_wrapper.sh --help"
    echo "check_wrapper.sh <command> <args>"
    echo ""
    echo "Example:"
    echo "check_wrapper.sh ping -c2 -o 127.0.0.1"
    echo ""
    echo "HOWTO NSCA"
    echo ""
    echo "Define ONE inline ENV VAR"
    echo ""
    echo "NSCA_PASSIVECHECK_DESC=\"\""
    echo ""
    echo " and in CROND use it like this:"
    echo ""
    echo "( NSCA_PASSIVECHECK_DESC=\"\" ./check_wrapper.sh /<NAGIOS_PLUGINS_PATH>/check_disk -w80 -c90)"
    echo ""
    echo ""
    exit 0;
}

# Execute and print results 
function runcommand () {
    MSG=`${CMDARGS}`
    RETURNCODE=$?
    if [ ${RETURNCODE} -eq ${NORM} ]; then
        STATUS="OK"
    elif [ ${RETURNCODE} -eq ${WARN} ]; then
        STATUS="Warning"
    elif [ ${RETURNCODE} -eq ${CRIT} ]; then
        STATUS="Critical"
    elif [ ${RETURNCODE} -eq ${UNKN} ]; then
        STATUS="Unknown"
    else
        RETURNCODE=${UNKN}
        STATUS="Unknown"
    fi

    # Verify if results will be sent through NSCA or NOT
    if [ -n "${NSCA_PASSIVECHECK_DESC+x}" ]; then
        ${ECHO} -e "${HOSTNAME}\t${NSCA_PASSIVECHECK_DESC}\t${RETURNCODE}\t${STATUS}:${MSG}" | ${SEND_NSCA} -H ${NAGIOS_HOST} -c ${SEND_NSCA_CFG}
    else
        ${ECHO} -ne "${RETURNCODE} : ${STATUS} : ${MSG}"
    fi

    restorepath
}

# Test if command exists
function trycmd () {
    $(type -p ${ACTION} &>/dev/null)
    RETURNCODE=$?
    if [ ${RETURNCODE} -ne 0 ]; then
        ${ECHO} -e "Command failed! Verify path, mode, and command name."
        ${ECHO} -ne "${RETURNCODE}"
        exit 1;
    else
        runcommand
    fi
}

# Run help or try to run command
if [ "${ACTION}" == "--help" ] || [ -z ${ACTION} ]; then
    myhelp
else
    # trycmd # to debug later
    runcommand
fi

exit ${RETURNCODE}
