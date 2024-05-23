#!/bin/sh
# Build an iocage jail under TrueNAS 13.0 and install Rustdesk Server
# git clone https://github.com/tschettervictor/truenas-iocage-rustdesk

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

#####
#
# General configuration
#
#####

# Initialize defaults
JAIL_IP=""
JAIL_INTERFACES=""
DEFAULT_GW_IP=""
INTERFACE="vnet0"
VNET="on"
POOL_PATH=""
JAIL_NAME="rustdesk"
CONFIG_NAME="rustdesk-config"
SERVER="127.0.0.1"

# Check for uptimekuma-config and set configuration
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
if ! [ -e "${SCRIPTPATH}"/"${CONFIG_NAME}" ]; then
  echo "${SCRIPTPATH}/${CONFIG_NAME} must exist."
  exit 1
fi
. "${SCRIPTPATH}"/"${CONFIG_NAME}"

JAILS_MOUNT=$(zfs get -H -o value mountpoint $(iocage get -p)/iocage)
RELEASE=$(freebsd-version | cut -d - -f -1)"-RELEASE"
# If release is 13.1-RELEASE, change to 13.2-RELEASE
if [ "${RELEASE}" = "13.1-RELEASE" ]; then
  RELEASE="13.2-RELEASE"
fi 

#####
#
# Input/Config Sanity checks
#
#####

# Check that necessary variables were set by uptimekuma-config
if [ -z "${JAIL_IP}" ]; then
  echo 'Configuration error: JAIL_IP must be set'
  exit 1
fi
if [ -z "${JAIL_INTERFACES}" ]; then
  echo 'JAIL_INTERFACES not set, defaulting to: vnet0:bridge0'
JAIL_INTERFACES="vnet0:bridge0"
fi
if [ -z "${DEFAULT_GW_IP}" ]; then
  echo 'Configuration error: DEFAULT_GW_IP must be set'
  exit 1
fi
if [ -z "${POOL_PATH}" ]; then
  echo 'Configuration error: POOL_PATH must be set'
  exit 1
fi
if [ -z "${SERVER}" ]; then
  echo 'Configuration error: SERVER must be set'
  exit 1
fi

# Extract IP and netmask, sanity check netmask
IP=$(echo ${JAIL_IP} | cut -f1 -d/)
NETMASK=$(echo ${JAIL_IP} | cut -f2 -d/)
if [ "${NETMASK}" = "${IP}" ]
then
  NETMASK="24"
fi
if [ "${NETMASK}" -lt 8 ] || [ "${NETMASK}" -gt 30 ]
then
  NETMASK="24"
fi

#####
#
# Jail Creation
#
#####

# Create the jail and install previously listed packages
if ! iocage create --name "${JAIL_NAME}" -r "${RELEASE}" interfaces="${JAIL_INTERFACES}" ip4_addr="${INTERFACE}|${IP}/${NETMASK}" defaultrouter="${DEFAULT_GW_IP}" boot="on" host_hostname="${JAIL_NAME}" vnet="${VNET}"
then
	echo "Failed to create jail"
	exit 1
fi

#####
#
# Directory Creation and Mounting
#
#####

# Create and mount directories
mkdir -p "${POOL_PATH}"/rustdesk
iocage exec "${JAIL_NAME}" mkdir -p /var/db/rustdesk-server
iocage fstab -a "${JAIL_NAME}" "${POOL_PATH}"/rustdesk /var/db/rustdesk-server nullfs rw 0 0

#####
#
# Rustdesk Server Installation 
#
#####

if ! iocage exec "${JAIL_NAME}" pkg install -y rustdesk-server
then
	echo "Failed to install rustdesk-server"
	exit 1
fi
iocage exec "${JAIL_NAME}" sysrc rustdesk_hbbr_enable="YES"
iocage exec "${JAIL_NAME}" sysrc rustdesk_hbbs_enable="YES"
iocage exec "${JAIL_NAME}" sysrc rustdesk_hbbs_ip="${SERVER}"

# Restart
iocage restart "${JAIL_NAME}"

echo "---------------"
echo "Installation Complete!"
echo "---------------"
echo "To start using your server, configure your clients to connect to ${SERVER} as the ID and relay server."
echo "---------------"
