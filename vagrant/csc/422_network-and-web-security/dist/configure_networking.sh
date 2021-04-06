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

readonly CURRENT_HOSTNAME="$(hostname -s)"
readonly ROUTER_HOSTNAME="router"
readonly ROUTER_IP="192.168.22.101"
readonly TESTING_HOSTNAME="testing"
readonly TESTING_IP="192.168.23.102"
readonly ROUTER_NETWORK="192.168.22.0/24"
readonly LOCAL_NETWORK="192.168.23.0/24"
readonly CURRENT_ROUTES="$(ip route)"
readonly REGEX_DEFAULT_ROUTE='^default.*via.*dev.*$'
REGEX_LOCAL_NETWORK="^${LOCAL_NETWORK}.*$"
CURRENT_DEFAULT_ROUTE=""
CURRENT_LOCAL_ROUTE=""

readonly INTERNAL_REGEX="${REGEX_LOCAL_NETWORK}"
INTERNAL_ROUTE=""
INTERNAL_NIC=""

if [[ "z${ROUTER_HOSTNAME}" == "z${CURRENT_HOSTNAME}" ]]; then
    printf 'Not manipulating static routes; this is the router VM (hostname = %s)\n' "${CURRENT_HOSTNAME}"
    exit 0
fi

# If we are on the `testing` box, the default route is on ROUTER_NETWORK
if [[ "z${TESTING_HOSTNAME}" == "z${CURRENT_HOSTNAME}" ]];  then
    unset REGEX_LOCAL_NETWORK
    REGEX_LOCAL_NETWORK="^${ROUTER_NETWORK}.*$"
fi

set +e  # Allow errors to occur and be non-fatal
for route in ${CURRENT_ROUTES[@]}; do
    if [[ "z" == "z${CURRENT_DEFAULT_ROUTE}" ]] ; then
        CURRENT_DEFAULT_ROUTE=$(printf '%s' ${route} | grep -iEs -- ${REGEX_DEFAULT_ROUTE} - )
    fi
    if [[ "z" == "z${CURRENT_LOCAL_ROUTE}" ]] ; then
        CURRENT_LOCAL_ROUTE=$(printf '%s' ${route} | grep -iEs -- ${REGEX_LOCAL_NETWORK} - )

    fi
    if [[ "z${TESTING_HOSTNAME}" == "z${CURRENT_HOSTNAME}" ]]; then
        INTERNAL_ROUTE=$(printf '%s' ${route} | grep -iEs -- ${INTERNAL_REGEX} - )
    fi
done
set -e  # Make errors fatal

# Prints the device name given a string from the output of `ip route`
readonly PYTHON_GET_DEV_CMD="import os,sys; t=os.environ.get('TO_PARSE').split(' '); print(t[t.index('dev')+1].strip())"
readonly CURRENT_DEFAULT_ROUTE_DEV="$(export TO_PARSE=\"${CURRENT_DEFAULT_ROUTE}\"; python3 -c ${PYTHON_GET_DEV_CMD})"
readonly NEW_DEFAULT_ROUTE_DEV="$(export TO_PARSE=\"${CURRENT_LOCAL_ROUTE}\"; python3 -c ${PYTHON_GET_DEV_CMD})"

function set_upstream_ip {
    readonly NEW_UPSTREAM_IP="${1}"
    readonly NEW_DEFAULT_ROUTE="default via ${NEW_UPSTREAM_IP} dev ${NEW_DEFAULT_ROUTE_DEV}"

    if !(printf '%s' ${CURRENT_DEFAULT_ROUTE} | grep -qs -- "${NEW_UPSTREAM_IP}" -) ; then
        printf 'Deleting the current default route: %s\n' "${CURRENT_DEFAULT_ROUTE}"
        ip route delete default
        printf 'Adding the new default route: %s\n' "${NEW_DEFAULT_ROUTE}"
        ip route add default via "${NEW_UPSTREAM_IP}" dev "${NEW_DEFAULT_ROUTE_DEV}"
    else
        printf 'Not manipulating static routes; default route appears to be OK: %s\n' "${CURRENT_DEFAULT_ROUTE}"
    fi
}

# Enable promiscuous mode on the NIC connected to the internal network (OS side)
printf 'Enabling promiscuous mode on network adapter: %s\n' "${NEW_DEFAULT_ROUTE_DEV}"
ip link set "${NEW_DEFAULT_ROUTE_DEV}" promisc on

# Disable traffic routing through NAT interface if not the router
if [[ "z${TESTING_HOSTNAME}" == "z${CURRENT_HOSTNAME}" ]] ; then # route the traffic for `testing` to be `router`
    readonly INTERNAL_NIC="$(export TO_PARSE=\"${INTERNAL_ROUTE}\"; python3 -c ${PYTHON_GET_DEV_CMD})"
    set_upstream_ip "${ROUTER_IP}"
    printf 'Enabling promiscuous mode on network adapter: %s\n' "${INTERNAL_NIC}"
    ip link set "${INTERNAL_NIC}" promisc on
else # route the traffic for `client` and `metasploitable` to testing
    set_upstream_ip "${TESTING_IP}"
fi

printf 'Network configuration complete\n'
exit 0
