## RAVpower WD02 modifications ##

When I had purchased a [http://www.ravpower.com/catalog/product/search/filehub](RAVPower FileHub)
[http://www.ravpower.com/rp-wd02-filehub-6000mah-power-bank-black.html](WD02), I quickly found that it wouldn't be
safe to operate in a public network, with lots of open ports, `telnet` being quite prominent.

There was a [https://web.archive.org/web/20141112135713/http://www.isartor.org/wiki/Securing_your_RavPower_Filehub_RP-WD01](Wiki page "**Securing your RavPower Filehub RP-WD01**" on http://www.isartor.org), and soon thereafter I found
[https://github.com/digidem/filehub-config](the original `filehub-config`), which was the starting
point for my own modifications.

I found that (on my WD02 - which is somewhat different from the WD01, details to be investigated)
some of the code snippets ("*scriptlets*") didn't work, and that they were combined in "some" order:
   * the name of the ethernet interface was wrong (that seems to be one of those differences)
   * the firewall would not be modified if the uplink was enabled/disabled
   * there was no IPv6 support
   * something didn't work with swap
   * a few scriptlets I didn't (and still don't) understand

What I did:
   * add prefix numbers for proper ordering of scriptlets
   * disable part of the scriptlets (in particular, the ones dealing with USB storage)
   * change makefile to make use of scriptlet numbering, and add comments to show "where this part came from"
   * add a new ntp.cfg for use in Europe
   * use `/.internal/donottouch/` instead of `/monitoreo/no_tocar/`; /.vst/swapfile to mimic recent FWs
   * debug, and change the firewall code, and the swap code
   * add logging (write all output next to the script)
   * patch /etc/*passwd to re-allow root logins
   * LEDs blink while `EnterRouterMode.sh` script is run - works for my WD02, need feedback for other devices
      * (In `telnet` console, run `/usr/sbin/pioctl {internet,status,wifi} {2,3}` - what happens?)
   * Add a `ChangePassword.sh` script that syncs encrypted passwords in multiple places (to be run in a `telnet` session)

This has been tested with firmwares up to 2.000.014, I didn't upgrade further yet since later fw versions may have telnetd disabled (or worse)
and therefore appreciate your feedback.

If you have a copy of previous firmware versions for WD01, WD02 or WD03 (or similar hardware), please contact me
(steve8x8 at googlemail).

Changes have been submitted to the original author but not incorporated so far, and since this fork has diverged
a lot, this will perhaps never happen anymore.

---

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

---

Future plans:
   * support newer fw releases (when detailed info is available)
   * work for WD01 and WD03 (and perhaps future hardware) - need detailed info
   * think about supporting a USB 3G modem (???)
   * ... (suggestions welcome)
