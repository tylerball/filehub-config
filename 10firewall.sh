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
