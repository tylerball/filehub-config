### Findings about firmware upgrades ###

** This is based on a couple of tools which may be malfunctioning, please check yourself.**

#### WD01 ####

   * __anyone?__
      * seen firmwares: 2.000.014 2.000.020 2.000.030

#### WD02 ####

   * __feedback welcome__
      * seen firmwares: 2.000.002 2.000.014 2.000.020

#####WD02 2.000.014 vs 2.000.002:#####
   * `/etc/telnetflag` was introduced, but handled in `/etc/initsh` to enable `root` shells
   * `telnetd` started by `/etc/rc.d/rc` if no file `/etc/checktelnetflag` or if file `/etc/telnetflag`
   * removed file `/etc/update/update.cfg` referring to IP 114.112.95.106:80, used by `/usr/sbin/au`

#####WD02 2.000.020 vs 2.000.014:#####
   * implements some firewall features (and even has `-m state --state RELATED,ESTABLISHED`)
      * --this possibly makes the `10firewall.sh` scriptlet obsolete (anyone can confirm?)--
      * not sure whether the setting persists over dis-/reconnect of WAN port
      * someone confirm that `/sbin/netinit.sh` isn't buggy?
   * `root` shell is now `/sbin/nologin` instead of `/bin/sh`
      * `ChangeRootPassword.sh` fixes this
      * `02enabletelnet.sh` scriptlet fixes it too
   * apparently, *removal* of a file `/etc/telnetflag` will enable a `telnetd` *once* (file will be back)
      * this may be true on first start
      * separate set of passwords in `/etc/telnet{passwd,shadow}` but unused
      * it might make sense to modify `/etc/init.d/opentelnet.sh` (or restore from .014)
   * NTP client now uses up to 4 servers (in `/etc/ntp/ntp.cfg`, separated by `:`)

#### WD03 ####

   * __anyone?__
      * seen firmwares: 2.000.016 (similar to F800 2.000.064)

---

#### Other makers ####

   * [https://forum.openwrt.org/viewtopic.php?pid=259413#p259413](this forum article contains a quite comprehensive list)

#### Other resources ####

   * http://wiki.openwrt.org/toh/ravpower/rp-wd02, https://forum.openwrt.org/viewtopic.php?id=54861
   * http://wiki.openwrt.org/toh/hootoo/tripmate-nano, https://forum.openwrt.org/viewtopic.php?id=53014

---

#### Known bugs ####

   * `minidlna` process (writing to `/data/UsbDisk1/Volume1/.vst/i4dlna/i4dlna.db`) isn't properly ended, leaving an unclean fs
      * address by adding a `/etc/rc.d/rc[06].d/K83minidlna` script?
   * `/sbin/shutdown h` invokes `hdparm -a /dev/sda` - why?
   * ...
