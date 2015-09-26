# Stops external network access to the device, increases security.
# Got to do this each time the WAN interface gets reconfig'd
# /etc/rc.local is NOT a good place to do this (but won't harm)
# /sbin/wan.sh -> /sbin/udhcpc.sh -> /etc/init,d/upnpd.sh
# /etc_ro/ppp/ip-up -> /etc/init.d/upnpd.sh restart
#  invokes /etc/init.d/control.sh (if exists)
# in more recent FW: control.sh == ipnpc.sh (called by /usr/sbin/ioos)
#  I *think* it's still safe to overwrite it,
#  but better have it in two steps: myfirewall.sh and control.sh

# Delete existing modification from file, if it exists
sed -i '/#START_MOD/,/#END_MOD/d' /etc/rc.local
sed -i '/setting firewall/d'      /etc/rc.local
sed -i '/#START_MOD/,/#END_MOD/d' /etc/init.d/control.sh

cat <<'EOF' >> /etc/rc.local
#START_MOD
echo /etc/rc.local setting firewall
/etc/init.d/myfirewall.sh start
#END_MOD
EOF

cat <<'EOF' >  /etc/init.d/myfirewall.sh
#! /bin/sh
# Call parameter (start, stop, ...) not used yet
#
# This script is invoked each time the WAN interface gets reconfigured
# Try to get name of external interface
. /sbin/global.sh

{
echo "Running $0" `date`
# check whether FW comes with own "stateful" iptables fw (WD03 .016)
# (availability of "-m state")
if grep -q 'iptables .*state' /sbin/netinit.sh
then
    echo "Using builtin \"state\" match"
    STATE=1
else
    echo "No \"state\" match, opening DNS and NTP ports"
    STATE=0
fi

echo Current WAN interface: ${wan_if}
# Apply firewall rules to external interface
echo Add ipv4 iptables entries for ${wan_if}
iptables -F INPUT

# if we have state supprt for iptables, we may drop everything
# except responses to valid DNS and NTP requests
if [ $STATE -eq 1 ]
then
    iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
else
    # Drop all tcp traffic incoming on wan_if, except DNS and NTP
    iptables -A INPUT -p tcp -i ${wan_if} --sport  53 -j ACCEPT
    iptables -A INPUT -p tcp -i ${wan_if} --dport  53 -j ACCEPT
    iptables -A INPUT -p tcp -i ${wan_if} --sport 123 -j ACCEPT
    iptables -A INPUT -p tcp -i ${wan_if} --dport 123 -j ACCEPT
    # Drop all udp traffic incoming on wan_if, except DNS and NTP
    iptables -A INPUT -p udp -i ${wan_if} --sport  53 -j ACCEPT
    iptables -A INPUT -p udp -i ${wan_if} --dport  53 -j ACCEPT
    iptables -A INPUT -p udp -i ${wan_if} --sport 123 -j ACCEPT
    iptables -A INPUT -p udp -i ${wan_if} --dport 123 -j ACCEPT
fi

iptables -A INPUT -p tcp -i ${wan_if} -j DROP
iptables -A INPUT -p udp -i ${wan_if} -j DROP
#
# Attempt to disable IPv6 completely, feedback appreciated
wan_if_x=`echo ${wan_if} | cut -d. -f1`
# There seems to be no way to disable_ipv6 via /proc/sys?
# Does this work:
#ip -6 route add unreachable default dev ${wan_if_x}
ip -6 route show \
| while read route dev if dummy
do
    if [ "$if" = "$wan_if_x" -o "$if" = "$wan_if" ]
    then
	echo "Delete ipv6 route on ${if}"
        ip -6 route del ${route} dev ${if}
    fi
done
# No IPv6 filter is installed, so remove IPv6 address on i/f
ip6addr=`/bin/ip addr show dev ${wan_if} | grep inet6 | awk '{print $2}'`
if [ -n "${ip6addr}" ]
then
    echo "Disable ipv6 addr on ${wan_if} ${wan_if_x}"
    ip -6 addr del "${ip6addr}" dev ${wan_if_x}
    ip -6 addr del "${ip6addr}" dev ${wan_if} 2> /dev/null
fi
#iptables -nL
#ip addr show
#ip -6 addr show
#ip -6 route show
} >> /tmp/firewall 2>&1
EOF
chmod +x /etc/init.d/myfirewall.sh
ls -l /etc/init.d/myfirewall.sh
rm -f /tmp/firewall

# Yes, we overwrite the existing control.sh which is a clone of upnpc.sh
cat <<'EOF' > /etc/init.d/control.sh
#! /bin/sh
#START_MOD
#?#/etc/init.d/upnpc.sh "$@"
/etc/init.d/myfirewall.sh "$@"
exit 0
#END_MOD
EOF
chmod +x /etc/init.d/control.sh
ls -l /etc/init.d/control.sh

# Make executable, and run it now!
echo pre-apply:
iptables -nL
ip addr show
ip -6 addr show
ip -6 route show
echo apply:
/etc/init.d/myfirewall.sh start
cat /tmp/firewall
echo post-apply:
iptables -nL
ip addr show
ip -6 addr show
ip -6 route show
