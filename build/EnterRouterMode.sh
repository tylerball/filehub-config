#!/bin/sh
echo -- ----------------- starting module 00header.sh
echo -- ----------------- finished module 00header.sh

echo -- ----------------- starting module 01prefix.sh
# Show how I'm called
echo Running $0 from `pwd` >  $0.out

# Run all stuff from within another shell
# Log all output

# To run with debugging info:
#/bin/sh -x <<'EOSCR' >> $0.out 2>&1
/bin/sh    <<'EOSCR' >> $0.out 2>&1
# ------------------------------------- #

export ERM_ROOT=`dirname $0`
echo -- ----------------- finished module 01prefix.sh

echo -- ----------------- starting module 10firewall.sh
# Stops external network access to the device, increases security.
# Got to do this each time the WAN interface gets reconfig'd
# /etc/rc.local is NOT a good place to do this
# Check /sbin/wan.sh:
# DHCP client mode -> /sbin/udhcpc.sh -> /etc/init,d/upnpd.sh
#  invokes /etc/init.d/control.sh (if exists)
# STATIC mode: not yet...
# PPPoE mode:  not yet...

# Delete existing modification from file, if it exists
sed -i '/#START_MOD/,/#END_MOD/d' /etc/rc.local
sed -i '/#START_MOD/,/#END_MOD/d' /etc/init.d/control.sh

# iptables has to be run *each time* the WAN interface is reconfigured!
cat <<'EOF' >> /etc/rc.local
echo `date` /etc/rc.local setting firewall
#START_MOD
/etc/init.d/control.sh
#END_MOD
EOF

cat <<'EOF' > /etc/init.d/control.sh
#START_MOD
# This script is invoked each time the WAN interface gets reconfigured
# Try to get name of external interface
. /sbin/global.sh
echo `date` WAN interface: ${wan_if} >> /tmp/firewall
# Apply firewall rules to external interface
for ip4if in ${wan_if}
do
    echo Add iptables entries for, and disable ipv6 on ${ip4if}
    # Drop all tcp traffic incoming on ip4if
    /bin/iptables -D INPUT -p tcp -i ${ip4if} -j DROP 2> /dev/null
    /bin/iptables -A INPUT -p tcp -i ${ip4if} -j DROP
    # Drop all udp traffic incoming on ip4if
    /bin/iptables -D INPUT -p udp -i ${ip4if} -j DROP 2> /dev/null
    /bin/iptables -A INPUT -p udp -i ${ip4if} -j DROP

    # There seems to be no way to disable_ipv6 via /proc/sys?
    # Does this work:
    ip6if=`echo ${ip4if} | cut -d. -f1`
    #/bin/ip -6 route add unreachable default dev ${ip6if}
    /bin/ip -6 route show | while read route dev if dummy; do
      if [ "$if" = "$ip6if" -o "$if" = "$ip4if" ]; then
        /bin/ip -6 route del ${route} dev ${if}
      fi
    done
    # No IPv6 filter is installed, so remove IPv6 address on i/f
    ip6addr=`/bin/ip addr show dev ${ip4if} | grep inet6 | awk '{print $2}'`
    if [ -n "${ip6addr}" ]; then
        /bin/ip -6 addr del "${ip6addr}" dev ${ip6if}
        /bin/ip -6 addr del "${ip6addr}" dev ${ip4if} 2> /dev/null
    fi
    #iptables -nL
    #ip addr show
    ip -6 addr show
    ip -6 route show
done >> /tmp/firewall 2>&1
#END_MOD
EOF
chmod +x /etc/init.d/control.sh

# Make executable, and run it now!
echo pre-apply:
iptables -nL
ip addr show
ip -6 route show
/etc/init.d/control.sh
echo post-apply:
cat /tmp/firewall
iptables -nL
echo -- ----------------- finished module 10firewall.sh

echo -- ----------------- starting module 15ntp.sh
# Replace NTP configuration

cat <<'EOF' > /etc/ntp/ntp.cfg
# must be != 0 for NTP to be used
switch=1
# number of hours between syncs
time=1
# only first entry is used? better don't rely on DNS
#server=ptbtime2.ptb.de:1.de.pool.ntp.org:0.europe.pool.ntp.org:2.asia.pool.ntp.org
server=192.53.103.104:ptbtime2.ptb.de:1.de.pool.ntp.org:0.europe.pool.ntp.org
EOF
echo -- ----------------- finished module 15ntp.sh

echo -- ----------------- starting module 20disktag.sh
# Updates /etc/init.d/disktag which determines the names of disks attached via USB

cat  <<'EOF' > /etc/init.d/disktag
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.1 UsbDisk 2
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.2 UsbDisk 3
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.3 UsbDisk 4
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.4 UsbDisk 5
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.5 UsbDisk 6
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.6 UsbDisk 7
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.7 UsbDisk 8
usb1/1-1/1-1.2/1-1.2.1/1-1.2.1.8 UsbDisk 9
usb1/1-1/1-1.2/1-1.2.1 UsbDisk 2
usb1/1-1/1-1.2/1-1.2.2 UsbDisk 3
usb1/1-1/1-1.2/1-1.2.3 UsbDisk 4
usb1/1-1/1-1.2/1-1.2.4 UsbDisk 5
usb1/1-1/1-1.1 UsbDisk 1
usb1/1-1/1-1.2 UsbDisk 2
usb1/1-1/1-1.3 UsbDisk 3
usb2/2-1/2-1.1 UsbDisk 1
usb2/2-1/2-1.2 UsbDisk 2
usb2/2-1/2-1.3 UsbDisk 3
EOF
echo -- ----------------- finished module 20disktag.sh

echo -- ----------------- starting module 40rsync.sh
# Copy rsync to the data store drive 

STORE_DIR=/.internal
CONFIG_DIR="$STORE_DIR"/donottouch

if [ -z "$ERM_ROOT" ]; then
    echo Environment ERM_ROOT unknown
elif [ ! -f rsync ]; then
    echo no rsync binary to copy to $CONFIG_DIR
elif [ -f $CONFIG_DIR/rsync ]; then
    echo rsync binary already exists in $CONFIG_DIR
fi

cp -p $ERM_ROOT/rsync $CONFIG_DIR/

echo copy returned $?
echo -- ----------------- finished module 40rsync.sh

echo -- ----------------- starting module 50swap.sh
# Add a swapfile on the data store drive 
# (rsync needs this for large file copies)

sed -i 's/^SWAP=.*/SWAP=swap/' /etc/firmware

cat <<'EOF' > /etc/init.d/swap
STORE_DIR=/.internal
CONFIG_DIR="$STORE_DIR"/donottouch
rm -f /tmp/swapinfo

echo "Running $0" > /tmp/swapinfo
while read device mountpoint fstype remainder; do
    echo "Checking $device at $mountpoint" >> /tmp/swapinfo
    if [ ${device:0:7} == "/dev/sd" -a -e "$mountpoint$CONFIG_DIR" ];then
            swapfile="$mountpoint$CONFIG_DIR"/swapfile
            if [ ! -e "$swapfile" ]; then
                echo "Creating swapfile $swapfile" >> /tmp/swapinfo
                # large blocksize is flash-friendlier
                dd if=/dev/zero of="$swapfile" bs=64k count=1024
                # create swapfile signature
                mkswap "$swapfile"
            fi
            swapon "$swapfile" >> /tmp/swapinfo 2>&1
            if [ $? -eq 0 ]; then
                echo "Turned on swap for $swapfile" >> /tmp/swapinfo
            else
                echo "There was an error turning on swap" >> /tmp/swapinfo
            fi
            exit 0
    fi
done < /proc/mounts
exit 0
EOF

# Make executable, and run right now!
chmod +x /etc/init.d/swap
echo pre-apply:
free
/etc/init.d/swap
echo post-apply:
free
echo -- ----------------- finished module 50swap.sh

echo -- ----------------- starting module 97flash.sh
# Persist configuration changes
/usr/sbin/etc_tools p
echo -- ----------------- finished module 97flash.sh

echo -- ----------------- starting module 98suffix.sh
# ------------------------------------- #
EOSCR
echo -- ----------------- finished module 98suffix.sh

echo -- ----------------- starting module 99footer.sh
# Delete this script so that it only runs once
#rm -- "$0"

# Keep this script for future reference
mv -f -- "$0" "$0".off

# Shutdown device?
# On WD02, does a factory reset, but no shutdown!!!
#/sbin/shutdown h

# Reboot device
/sbin/shutdown r
echo -- ----------------- finished module 99footer.sh
