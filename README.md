# truenas-iocage-rustdesk
Script to create an iocage jail on TrueNAS with rustdesk server.

This script will create an iocage jail on TrueNAS CORE 13.0 with the latest release of rustdesk-server pkg. It will configure the jail to store the keys needed for secure connection outside the jail, so they will not be lost in the event you need to rebuild the jail.

## Status
This script will work with TrueNAS CORE 13

## Usage

### Prerequisites

You will need to create
- 1 Dataset named `rustdesk` in your pool.
e.g. `/mnt/mypool/apps/rustdesk`

If this is not present, a directory `/rustdesk` will be created in `$POOL_PATH`. You will want to create the dataset, otherwise a directory will just be created. Datasets make it easy to do snapshots etc...

### Installation
Download the repository to a convenient directory on your TrueNAS system by changing to that directory and running `git clone https://github.com/tschettervictor/truenas-iocage-rustdesk`.  Then change into the new `truenas-iocage-rustdesk` directory and create a file called `rustdesk-config` with your favorite text editor.  In its minimal form, it would look like this:
```
JAIL_IP="192.168.1.199"
DEFAULT_GW_IP="192.168.1.1"
POOL_PATH="/mnt/mypool/apps"
```
Many of the options are self-explanatory, and all should be adjusted to suit your needs, but only a few are mandatory.  The mandatory options are:

* JAIL_IP is the IP address for your jail.  You can optionally add the netmask in CIDR notation (e.g., 192.168.1.199/24).  If not specified, the netmask defaults to 24 bits.  Values of less than 8 bits or more than 30 bits are invalid.
* DEFAULT_GW_IP is the address for your default gateway
* POOL_PATH is the path for your data pool.
 
In addition, there are some other options which have sensible defaults, but can be adjusted if needed.  These are:

* JAIL_NAME: The name of the jail, defaults to "rustdesk"
* INTERFACE: The network interface to use for the jail.  Defaults to `vnet0`.
* JAIL_INTERFACES: Defaults to `vnet0:bridge0`, but you can use this option to select a different network bridge if desired.  This is an advanced option; you're on your own here.
* VNET: Whether to use the iocage virtual network stack.  Defaults to `on`.

### Execution
Once you've downloaded the script and prepared the configuration file, run this script (`script rustdesk.log ./rustdesk-jail.sh`).  The script will run for maybe a minute.  When it finishes, your jail will be created, Rustdesk will be installed, and you should be able to start using it for remote access.

### Notes
The key files needed for secure connections are stored outside the jail in `$POOL_PATH`
