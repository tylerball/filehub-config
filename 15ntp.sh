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
