# Delete this script so that it only runs once
#rm -- "$0"

# Keep this script for future reference
mv -f -- "$0" "$0".off

# Shutdown device?
# On WD02, does a factory reset, but no shutdown!!!
#/sbin/shutdown h

# Reboot device
/sbin/shutdown r
