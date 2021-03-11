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

printf "Using (%s) as the path of the provisioner script\n" "${THIS_SCRIPT}"

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
# Provisioner part

# Ensure packages are up to date
apt-get update
apt-get upgrade -y

# Install wireshark noninteractively
debconf-set-selections <<- _EOF_
wireshark-common wireshark-common/install-setuid boolean true
_EOF_
DEBIAN_FRONTEND=noninteractive apt-get install -y wireshark
# allow `vagrant` user to capture packets without elevating to root
usermod -aG wireshark vagrant

# Install python
apt-get install -y python3 python3-pip
python3 -m pip install --pre scapy[complete]

cd /tmp/
mkdir mitmproxy
cd mitmproxy
wget "https://snapshots.mitmproxy.org/6.0.2/mitmproxy-6.0.2-linux.tar.gz"
tar xzvf mitmproxy-6.0.2-linux.tar.gz
install mitmdump /usr/local/bin/
install mitmproxy /usr/local/bin/
install mitmweb /usr/local/bin/
