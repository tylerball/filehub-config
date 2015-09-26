# Replace NTP configuration

cat <<'EOF' > /etc/ntp/ntp.cfg
# must be != 0 for NTP to be used
switch=1
# number of hours between syncs
time=3
# older firmwares used only first server entry
# newer firmwares use max. four server entries
# depending on firewall settings, we cannot always rely on DNS
# this is for Germany and Central Europe:
#server=ptbtime2.ptb.de:1.de.pool.ntp.org:0.europe.pool.ntp.org:2.asia.pool.ntp.org
server=192.53.103.104:ptbtime2.ptb.de:1.de.pool.ntp.org:0.europe.pool.ntp.org
EOF
