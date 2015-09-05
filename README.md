## RAVpower WD02 modifications ##

When I had purchased a [http://www.ravpower.com/catalog/product/search/filehub](RAVPower FileHub)
[http://www.ravpower.com/rp-wd02-filehub-6000mah-power-bank-black.html](WD02), I quickly found that it wouldn't be
safe to operate in a public network, with lots of open ports, `telnet` being quite prominent.

There was a [https://web.archive.org/web/20141112135713/http://www.isartor.org/wiki/Securing_your_RavPower_Filehub_RP-WD01](Wiki page "**Securing your RavPower Filehub RP-WD01**" on
http://www.isartor.org), and soon thereafter I found
[https://github.com/digidem/filehub-config](the original `filehub-config`), which was the starting
point for my own modifications.

I found that (on my WD02 - which is somewhat different from the WD01, details to be investigated)
some of the code snippets didn't work, and that they were combined in "some" order:
   * the name of the ethernet interface was wrong (that seems to be one of those differences)
   * the firewall would not be modified if the uplink was enabled/disabled
   * there was no IPv6 support
   * something didn't work with swap
   * a few snippets I didn't (and still don't) understand

What I did:
   * add prefix numbers for proper ordering of snippets
   * disable part of the snippets
   * change makefile to make use of snippet numbering, and add comments to show "where this part came from"
   * add a new ntp.cfg for use in Europe
   * use `/.internal/donottouch/` instead of `/monitoreo/no_tocar/`
   * debug, and change the firewall code, and the swap code
   * add logging (write all output next to the script)
   * Add a `ChangePassword.sh` script that syncs encrypted passwords in multiple places (to be run in a `telnet` session)

This has been tested with firmwares up to 2.000.014, I didn't upgrade firther since later fw versions may have telnetd disabled (or worse).

If you have a copy of previous firmware versions for WD01, WD02 or WD03, please contact me.

Changes have been submitted to the original author but not incorporated so far. That's why there's this fork now.

---

### Findings about firmware upgrades ###

** This is based on a couple of tools which may be malfunctioning, please check yourself.**

#### WD01 ####

   * __anyone?__

#### WD02 ####

#####WD02 2.000.020 vs 2.000.014:#####
   * implements some firewall features (and even has `-m state --state RELATED,ESTABLISHED`)
      * this possibly makes the 10firewall.sh snippet obsolete (anyone can confirm?)
      * not sure whether the setting persists over dis-/reconnect of WAN port
      * although the code looks like there's a bug in `/sbin/netinit.sh`...
   * `root` shell is now `/sbin/nologin` instead of `/bin/sh`
      * `ChangeRootPassword.sh` fixes this
   * apparently, *removal* of a file `/etc/telnetflag` will enable a `telnetd` *once* (file will be back)
      * this may be true on first start
      * separate set of passwords in `/etc/telnet{passwd,shadow}` but unused
      * it might make sense to modify `/etc/init.d/opentelnet.sh` (or restore from .014)
   * NTP client now uses up to 4 servers (in `/etc/ntp/ntp.cfg`, separated by `:`)

#####WD02 2.000.014 vs 2.000.002:#####
   * `/etc/telnetflag` was introduced, but handled in `/etc/initsh` to enable `root` shells
   * `telnetd` started by `/etc/rc.d/rc` if no file `/etc/checktelnetflag` or if file `/etc/telnetflag`
   * removed file `/etc/update/update.cfg` referring to IP 114.112.95.106:80, used by `/usr/sbin/au`

#### WD03 ####

   * __anyone?__

---

Future plans:
   * support newer fw releases (when detailed info is available)
      * including patching the `/etc/passwd` (set `root` shell to `/bin/sh`)
   * work for WD01 and WD03 (and perhaps future hardware) - need detailed info
   * think about supporting a USB 3G modem (???)
   * ... (suggestions welcome)

---

The original README follows:

---

RAVPower Automation
===================

This collection of scripts automate functionality for copying and backing up files using a [RAVPower Filehub](http://www.ravpower.com/ravpower-rp-wd01-filehub-3000mah-power-bank.html).

- [x] Change the default password
- [x] Block external network access
- [x] Copy files from SD Card to USB drive automatically
- [ ] Rename & organize files using EXIF data
- [x] Backup / sync between two USB drives
- [x] Add a swap file on a USB drive
- [ ] Allow import of [ODK Collect](http://opendatakit.org/use/collect/) data from smart phones over USB
- [ ] Allow import of [ODK Collect](http://opendatakit.org/use/collect/) data from smart phones over wifi

How to hack the Filehub embedded Linux
--------------------------------------

The RAVPower Filehub runs embedded Linux, which is a cut-down version of Linux with a low memory footprint. Most of the filesystem is read-only apart from the contents of `/etc` and `/tmp`, but changes are not persisted across reboots.

The easiest way to "hack" / modify the configuration of the embedded Linux is to create a script `EnterRouterMode.sh` on an SD card and put the card in the Filehub. The current firmware (2.000.004) will execute a script with this name with root permissions when the SD card is mounted.

The `EnterRouterMode.sh` script modifies scripts within `/etc` and persists changes by running `/usr/sbin/etc_tools p`.

To use, download the EnterRouterMode.sh script, copy it to the top-level folder of an SD card, and insert it into the filehub device.

Building from source
--------------------

```shell
git clone https://github.com/digidem/filehub-config.git
make
```

Change the default password
---------------------------

The default root password on RAVPower Filehub devices is 20080826. This is available on several online forums. Best change it. You can do this by telnet (username: root password: 20080826):

```shell
telnet 10.10.10.254
passwd
```

or create a file `EnterRouterMode.sh` on an SD card and insert it into the Filehub:

```shell
#!/bin/sh
passwd <<'EOF'
newpassword
newpassword
EOF
/usr/sbin/etc_tools p
```

Block external network access
-----------------------------

By default it is possible to telnet into the Filehub from an external network if you know what you are doing. This script adds iptables rules to `/etc/rc.local` ([source](http://www.isartor.org/wiki/Making_the_RavPower_Filehub_RP-WD01_work_with_non-free_hotspots))

Copy files from SD card automatically
-------------------------------------

The script runs when any USB device is attached. It checks whether an SD card is present, and it looks for an external USB drive (can be a thumb drive or a USB disk drive) with a folder `/monitoreo/config` which contains an [rsync](http://rsync.samba.org/) binary built for embedded linux. There is not enough memory on the filehub device to store the rsync binary on the device itself.

The script uses rsync to copy files, which should be resilient to interuption mid-copy and resume where it left off. Source files are removed from the SD card as they are copied to the external drive.

A folder is created for each SD card, identified by a [UUID](http://en.wikipedia.org/wiki/Universally_unique_identifier). It would be ideal to use the serial number for an SD card for the UUID, but unfortunately it is not possible to access this. `udevadm info -a -p  $(udevadm info -q path -n /dev/sda) | grep -m 1 "ATTRS{serial}" | cut -d'"' -f2` returns the serial number for the card reader, rather than the SD card. Instead we generate a UUID using `cat /proc/sys/kernel/random/uuid` and store that on the SD card. Bear in mind if an SD card is re-formatted in the camera then this UUID will be lost, so the card will appear as a new card next time it is inserted. Using a UUID allows for transfers to be interupted and resumed later.

If more than 9999 photos are taken with a camera, filenames will be reused. Similarly if an SD card is used in a different camera, filenames will be repeated. This would lead to overwriting files if we just stored all photos from each SD card in a single folder. Instead we create a subfolder for each import. Ideally this would be named with the date of the import, but the clock on the RavPower device cannot be relied upon without internet access. Instead we use the date of the most recent photo on the SD Card as the name of the subfolder.

When the SD card or USB drive is removed, we kill the rsync process, otherwise it hangs around.

Backup between two USB hard drives
----------------------------------

If a second drive is attached with a folder "Backup" then an automatic backup process will begin. Each backup drive is linked to the original drive via the original drive serial number. e.g. if you have two drives with original files and one backup drive for each, it will not backup to the wrong drive because it will detect the serial. The link is created the first time you create the backup, by writing a file ".backup_id" to the backup folder.

At this stage older versions and deleted files are not kept. The backup drive is an exact mirror of the original drive. Backups are created via rsync with the following command:

```sh
rsync -vrm --size-only --delete-during --exclude ".?*" --partial-dir "$partial_dir" --exclude "swapfile" --log-file /tmp/rsync_log "$source_dir"/ "$target_dir"
```

Comments and suggestions for the rsync options are most welcome!

Swap file
---------

The RavPower Filehub only has 28Mb of memory, and about 2Mb of free memory. Rsync needs around [100 bytes for each file](http://rsync.samba.org/FAQ.html#4). To avoid out of memory issues we create a 64Mb swapfile on the USB drive when it is connected. This appears to speed up rsync and *should* avoid memory issues. I have not yet tested with thousands of files.

Renaming with EXIF
------------------

I would like photo filenames to be unique, so we can use them as a UUID. The best way would be to read the EXIF capture date, and prepend that to the filename. Although it might be possible to do that with just the file creation date and time. To use EXIF we would need to cross-compile an EXIF utility for the MIPS architecture used in the RavPower.

ODK Collect Imports
-------------------

We are using [ODK Collect](http://opendatakit.org/use/collect/) for data collection. This Android app stores data in a folder on the phone storage, and allows for sending that info via a multi-part form submission. There are 3 options for getting that data onto the filehub:

1. Modify the [form submission code](https://code.google.com/p/opendatakit/source/browse/src/org/odk/collect/android/tasks/InstanceUploaderTask.java?repo=collect) in ODK collect so that instead of a multipart form upload, it uploads the form as an XML file to the WebDav server on the RavPower. The Ravpower can be configured so that the ODK server address will redirect locally when no internet connection is present.

2. Write a small CGI script that can run on the RavPower to accept a multi-part form submission (containing form XML and associated media/photos). It would need to rename the files with the form submission UUID. Could face memory and processing speed limitations.

3. Transfer the data via a USB connection. Android >4.0 only connects via MTP, which varies in implmentation in Android. The best seems to be [go-mtpfs](https://github.com/hanwen/go-mtpfs) which would need to be cross-compiled with GO for MIPS archetecture, which seems is possible. All libraries would need to be statically linked. This is potentially the most reliable solution.

 