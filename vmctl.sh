#!/bin/sh
#
# vmctl - VMware ConTroL script - https://johan.pp.se
#
# Makes it easier to do power related tasks for VMware VMs.
#
#
# Copyright (c) 2012, Johan Hedberg <mail@johan.pp.se>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met: 
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 

# Usage info
usage() {
	errstr="$1"
	echo "vmctl - VMware ConTroL script - Johan Hedberg, 2012 - https://johan.pp.se" >&2
	if [ "$errstr" != "" ]; then
		echo >&2
		echo "Error: $errstr" >&2
		echo >&2
	fi
	echo "Usage: vmctl -s <server> -u <user> -a <action> [-v <vmname>]" >&2
	echo >&2
	echo "Action is one of: start|stop|restart|hardreset|getstate|list" >&2
	echo >&2
	exit 1
}

# Error handler
check_error() {
	if [ $1 -eq 0 ]; then
		echo "OK"
	else
		echo "FAIL"
		exit $1
	fi
}

# Get args
server=""
ruser=""
action=""
vmname=""
while getopts 's:u:a:v:h' opt; do
	case "$opt" in
		h)
			usage
		;;
		s)
			server="$OPTARG"
		;;
		u)
			ruser="$OPTARG"
		;;
		a)
			action="$OPTARG"
		;;
		v)
			vmname="$OPTARG"
			if [ "$vmname" = "" ] && [ "$action" != "list"]; then
				usage
			fi
		;;
		\?)
			usage "Invalid argument list."
		;;
		*)
			usage "Invalid argument list."
		;;
	esac
done

# Check the arguments
if [ "$server" = "" ] || [ "$ruser" = "" ] || [ "$action" = "" ]; then
	usage "Missing server, user or action."
elif [ "$action" != "list" ] && [ "$vmname" = "" ]; then
	usage "Missing VM name, try the action 'list'."
fi

# Get VM id
if [ "$action" != "list" ]; then
	vmid=$(ssh $ruser@$server "vim-cmd vmsvc/getallvms" | egrep "^[0-9]+[\s\t 	]+$vmname" | awk '{print $1;}')
	if [ "$vmid" = "" ]; then
		usage "Couldn't get VM id, check that the VM name is correctly given."
	fi
fi

# Run the action
case $action in
	"start")
		ssh $ruser@$server "vim-cmd vmsvc/power.on $vmid"
		check_error $?
	;;
	"stop")
		ssh $ruser@$server "vim-cmd vmsvc/power.off $vmid"
		check_error $?
	;;
	"restart")
		ssh $ruser@$server "vim-cmd vmsvc/power.reboot $vmid"
		check_error $?
	;;
	"hardreset")
		ssh $ruser@$server "vim-cmd vmsvc/power.reset $vmid"
		check_error $?
	;;
	"getstate")
		ssh $ruser@$server "vim-cmd vmsvc/power.getstate $vmid"
	;;
	"list")
		ssh $ruser@$server "vim-cmd vmsvc/getallvms"
	;;
	*)
		usage "Invalid action."
	;;
esac
