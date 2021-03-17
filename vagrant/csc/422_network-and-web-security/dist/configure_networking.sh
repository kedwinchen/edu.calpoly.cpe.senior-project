#!/bin/bash

set -eEuo pipefail

################################################################################
# Determine where this script is stored

# Solve for the current directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

THIS_SCRIPT="${DIR}/$(basename ${0})"

printf "Using (%s) as the absolute path of this script\n" "${THIS_SCRIPT}"

################################################################################
# Check permissions

printf "Running as %s (%s)\n" "$(whoami)" "$(id)"

if [[ $EUID -ne 0 ]] ; then
    printf "%s\n" "Attempting to elevate..."
    # re-launch as root
    exec sudo -i bash "${THIS_SCRIPT}"
fi

# this should not be able to occur
if [[ $EUID -ne 0 ]] ; then
    # at this point, we should be running as root
    # if not, then using `sudo` failed
    printf "%s\n" "Could not elevate to root"
    exit 1
else
    printf "%s\n" "Successfully elevated privileges"
fi

################################################################################

IFS=$'\n'

readonly ROUTER_IP="192.168.22.101"
readonly LOCAL_NETWORK="192.168.22.0/24"
readonly CURRENT_ROUTES="$(ip route)"
readonly REGEX_DEFAULT_ROUTE='^default.*via.*dev.*$'
readonly REGEX_LOCAL_NETWORK="^${LOCAL_NETWORK}.*$"
CURRENT_DEFAULT_ROUTE=""
CURRENT_LOCAL_ROUTE=""

set +e  # Allow errors to occur and be non-fatal
for route in ${CURRENT_ROUTES[@]}; do
    if [[ "z" == "z${CURRENT_DEFAULT_ROUTE}" ]] ; then
        CURRENT_DEFAULT_ROUTE=$(printf '%s' ${route} | grep -iEs -- ${REGEX_DEFAULT_ROUTE} - )
    fi
    if [[ "z" == "z${CURRENT_LOCAL_ROUTE}" ]] ; then
        printf "route = %s\n" "${route}"
        printf '%s' ${route} | grep -iEs -- ${REGEX_LOCAL_NETWORK} -
        CURRENT_LOCAL_ROUTE=$(printf '%s' ${route} | grep -iEs -- ${REGEX_LOCAL_NETWORK} - )
    fi
done
set -e  # Make errors fatal

printf 'CURRENT_DEFROUTE = %s\n' "${CURRENT_DEFAULT_ROUTE}"
printf 'CURRENT_LOCROUTE = %s\n' "${CURRENT_LOCAL_ROUTE}"
# Prints the device name
# python3 -c "import os; t=os.environ.get('LOCAL_ROUTE').split(' '); print(t[t.index('dev')+1].strip())")
readonly PYTHON_GET_DEV_CMD="import os; t=os.environ.get('TO_PARSE').split(' '); print(t[t.index('dev')+1].strip())"
readonly CURRENT_DEFAULT_ROUTE_DEV="$(export TO_PARSE=\"${CURRENT_DEFAULT_ROUTE}\"; python3 -c ${PYTHON_GET_DEV_CMD})"
readonly NEW_DEFAULT_ROUTE_DEV="$(export TO_PARSE=\"${CURRENT_LOCAL_ROUTE}\"; python3 -c ${PYTHON_GET_DEV_CMD})"
readonly NEW_DEFAULT_ROUTE="default via ${ROUTER_IP} dev ${NEW_DEFAULT_ROUTE_DEV}"

# Enable promiscuous mode on the NIC connected to the internal network (OS side)
ip link set "${NEW_DEFAULT_ROUTE_DEV}" promisc on

# Disable traffic routing through NAT interface if not the router
if ! (printf '%s' ${CURRENT_ROUTES} | grep -qs -- "${ROUTER_IP}" -) ; then
    printf 'Deleting the current default route: %s\n' "${CURRENT_DEFAULT_ROUTE}"
    ip route delete default
    printf 'Adding the new default route: %s\n' "${NEW_DEFAULT_ROUTE}"
    ip route add default via "${ROUTER_IP}" dev "${NEW_DEFAULT_ROUTE_DEV}"
fi
set +x
