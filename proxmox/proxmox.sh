#! /bin/bash
# proxmox.sh - Proxmox Management Script to backup/move/restore Proxmox VM's
# Version - 0.1
# Date - 10/08/2011
# Francisco Cabrita - <francisco.cabrita@gmail.com>

PROX01_IP="10.0.0.1"
PROX02_IP="10.0.0.2"
PROX01_HOSTNAME="proxmox01-h01"
PROX02_HOSTNAME="proxmox02-h02"

DUMPDIR="/vz/dumps"

HOST=`hostname`

if [ ${HOST} = ${PROX01_HOSTNAME} ]; then
	ORIG=${PROX01_IP}
	DEST=${PROX02_IP}
else
	ORIG=${PROX02_IP}
	DEST=${PROX01_IP}
fi

ARGS=4
E_BADARGS=85

ACTION=$1
ARG1=$1
ARG2=$2
ARG3=$3
ARG4=$4

# - - - - - - - - - - - - - - - - - - - - - - - - -

function help {
	echo
	echo "Usage:"
	echo " proxmox help"
	echo " proxmox list vms"
	echo " proxmox list storage"
	echo " proxmox backup vmid"
	echo " proxmox move vmid"
	echo " proxmox restore backup_vmid storage restore_vmid"
	echo
}

function list () {
	case "${ARG2}" in
		"vms")
			echo "Local VMS [ ${ORIG} ]"
			qm list
			echo
			echo "Remote VMS [ ${DEST} ]"
			ssh root@${DEST} 'qm list'
			;;
		"storage")
			echo "Local Storage [ ${ORIG} ]"
			grep ':' /etc/pve/storage.cfg | sort
			echo
			echo "Remote Storage [ ${DEST} ]"
			ssh root@${DEST} 'grep ':' /etc/pve/storage.cfg | sort'
			;;
		"" | *)
			echo "Use 'list vms' or 'list storage'"
			;;
	esac
	exit 0;
}

function backup () {
	VMID=${ARG2}
	if [ -z ${VMID} ]; then
		echo "No VMID defined to backup! Exiting..."
		exit 1;
	fi
	$(qm list | awk -F' ' '{print $1}' | grep -v 'VMID' > /tmp/vmlist)
	if grep -q "${VMID}" /tmp/vmlist
	then
		echo "Backup here it goes"
		vzdump --dumpdir ${DUMPDIR} --stop --compress ${VMID}
		exit 0;
	else
		echo "VM ${VMID} not found!"
		exit 1;
	fi
	rm /tmp/vmlist
	exit 0;
}

function move () { 
	VMID=${ARG2}
	if [ -z ${VMID} ]; then
		echo "No VMID defined to move! Exiting..."
		exit 1;
	fi
	$(ls /vz/dumps/vzdump-qemu-${VMID}-*.tgz | awk -F'/' '{print $4}' > /tmp/bklist)
	if grep -q "vzdump-qemu-${VMID}-" /tmp/bklist
	then
		echo "Found backup of VM ${VMID}. Moving..."
		scp ${DUMPDIR}/vzdump-qemu-${VMID}-*.tgz root@${DEST}:/${DUMPDIR}
		exit 0;
	else
		echo "VM ${VMID} not found"
		exit 1;
	fi
	rm /tmp/bklist
	exit 0;
}

function restore () {
	VMID_B=${ARG2}
	STORAGE=${ARG3}
	VMID_R=${ARG4}
	if [ -z ${VMID_B} ]; then
		echo "No VMID of backup defined to restore! Exiting..."
		exit 1;
	fi
	if [ -z ${VMID_R} ]; then
		echo "No restore VMID defined to use! Exiting..."
		exit 1;
	fi
	if [ -z ${STORAGE} ]; then
		echo "No destination storage defined!"
		echo "Please choose it with $ proxmox list storage"
		echo "exiting..."
		exit 1;
	fi
	ssh root@${DEST} 'grep ':' /etc/pve/storage.cfg | sort' > /tmp/stlist
	if ! grep -q "${STORAGE}" /tmp/stlist
	then
		echo "ERROR: Destination storage [ ${STORAGE} ] not found! Exiting"
		exit 1;
	fi
	rm /tmp/stlist
	ssh root@${DEST} "qm list | grep -v VMID" > /tmp/vmlist01
	awk -F' ' '{print $1}' /tmp/vmlist01 > /tmp/vmlist
	if grep -q "${VMID_R}" /tmp/vmlist
	then
		echo "ERROR: VMID Already exists! Exiting..."
		exit 1;
	else
		echo "going to restore this bitch!"
ssh root@${DEST} "qmrestore --storage ${STORAGE} ${DUMPDIR}/vzdump-qemu-${VMID_B}-*.tgz ${VMID_R}"
	fi
	echo "Don't forget to clean ${DUMPDIR}"
	rm /tmp/vmlist*
	exit 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - -

case "${ACTION}" in
	"list" ) list ;;
	"backup" ) backup ;;
	"move" ) move ;;
	"restore" ) restore ;;
	"help" | "" | * ) help exit 0; ;;
esac

exit 0;
