#!/bin/sh
# Change the root password only!

# ---------------------------------------------------------------
# INSTRUCTIONS:
# Copy the script to your SD card.
# Login as *root* (using the old password).
#   cd /data/UsbDisk1/Volume1
#   sh ChangeRootPassword.sh
# Enter your new password twice.
# Carefully check the output. (You know how to reset the device?)
# If you are absolutely sure, write your changes
#   /usr/sbin/etc_tools p
# ---------------------------------------------------------------


# With WD-02 firmware 2.000.014, "passwd" only modifies /etc/shadow
# but telnetd still uses /etc/passwd, apparently.

# Please use the web interface to change the user (admin) password
# as this goes into multiple places - and the web interface does
# change both /etc/passwd and /etc/shadow!

# passwd does NOT accept stdin from a file, therefore this script
# cannot be included into EnterRouterMode.sh!

echo pre-change:
date
ls -l /etc/passwd /etc/shadow
grep ^root: /etc/passwd /etc/shadow

passwd

echo in-change:
date
ls -l /etc/passwd /etc/shadow
grep ^root: /etc/passwd /etc/shadow

# This changed the second field in /etc/shadow, extract it
ENCPASS=`awk -F: '/^root:/{print $2}' /etc/shadow`
echo encrypted password: $ENCPASS
OLDPASS=`awk -F: '/^root:/{print $2}' /etc/passwd`
echo overwriting old password: $OLDPASS
cp -p /etc/passwd /etc/passwd-
awk -F: -vPASS="$ENCPASS" \
    '{if(/^root:/){$2=PASS;}printf("%s:%s:%s:%s:%s:%s:%s\n",$1,$2,$3,$4,$5,$6,$7)}' \
    /etc/passwd- > /etc/passwd

echo post-change:
date
ls -l /etc/passwd /etc/shadow
grep ^root: /etc/passwd /etc/shadow

echo "Now check whether you can actually use this password."
echo "Do not forget to SAVE your changes using \"/usr/sbin/etc_tools p\" !"
