# remove /etc/init.d/opentelnet.sh
# remove /etc/*telnetflag
# enable root shell

if [ -f /etc/init.d/opentelnet.sh ]; then
    echo remove opentelnet script
    rm -f /etc/init.d/opentelnet.sh
fi
if [ -f /etc/telnetflag ]; then
    echo remove telnetflag
    rm -f /etc/telnetflag
fi
if [ -f /etc/checktelnetflag ]; then
    echo remove checktelnetflag
    rm -f /etc/checktelnetflag
fi
echo enable root shell
sed -i "s|:/root:/sbin/nologin|:/root:/bin/sh|" /etc/passwd
