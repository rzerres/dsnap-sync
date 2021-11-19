<!-- dsnap-sync README.md -->
<!-- version: 0.6.6 -->

# dsnap-sync

<p align="center">
  <span>English</span> |
  <!-- a href="lang/spanish">Spanish</a> | -->
  <a href="lang/german">Deutsch</a>
</p>

## About

`dsnap-sync` is designed to backup btrfs formated filesystems.
It takes advantage of the specific snapshots functionality btrfs offers
and combines it with managemnet functionality of `snapper`.

`dsnap-sync` creates backups as btrfs-snapshots on a selectable target device.
Plug in and mount any btrfs-formatted device to your system. Supported targets
may be either local attached USB drives, automountable RAID devices or LTFS
aware tapes. All supported targets can be located on a remote host.
If possible the backup process will send incremental snapshots to the target
drive. If the snapshot will be stored on a remote host, the transport will be
secured with ssh.

The tool is implemented as a posix shell script (dash), to keep the footprint
small. `dsnap-sync` will support interactive and time scheduled backup processes.
Scheduling should be implemented as a pair of systemd service and timer-units.
The [example section](usr/share/doc/dsnap-sync/Examples.md#systemd)
will offer details as a reference point.

## Backup process

The default `dsnap-sync` backup process will iterate through all defined `snapper`
configurations that are found on your source system.

If you prefer to have single processes for each configuration or configuration
groups, you are free to define isolated systemd-units. They will be triggerd
interactively or via timer units. `dsnap-sync` will cycle through each
referenced `snapper` configuration (option `-c` or `--config`).

For each selected `snapper` configuration `dsnap-sync`

* will present/select target device informations
* will prepare snapper structures
* will perform the actual backup
  (handle backupdir, handle snapper structures, handle btrfs send / btrfs recieve)
* will finalize the actual backup
  (update snapper metadata for each source and target snapshot)
* will perform cleanup tasks

Usualy other tools will document this proccess as a disk to disk (d2d) backup.
If possible `dsnap-sync` will levarage `btrfs send` capabilities to only
send deltas. It will compare snapshot data of the source snapshot with available
snapshot data on the target device. If a common snapshot id exists on source and
target, `dsnap-sync` will prepare the `btrfs send / btrfs receive` pipe to use
them respectively. This functionality dasticly reduces the time a sync process
will need to complete compared to a full backup process.

### Interactive backups

An interactive process will gide you to select a backup target.
You can pre-select the target via [command line options](./README.md#Options).
To uniquely define / select a target devices you either need to choose

* a pair of a btrfs UUID and SUBVOLID
* a TARGET name (read 'mount point')
* a MediaPool / Tape VolumeName

This will asure, that `dsnap-sync` can distinguish backup processes that
have a commen source device, but save data to different target devices. As
an example it might be advisable, to save the project subvolume redundantly
on to independent targets (disk and tape).

Before `dsnap-sync` will perform the backup, it will present the backupdir,
and spit out the source and target locations. You have to confirm or adapt
the given values. You may use commandline options to supress interaction
(e.g --noconfirm, --batch).


### Scheduled backups

A scheduled process should be defined as a systemd unit. Inside the unit
definition the execution parameter will take the `dsnap-sync` call, appending
all needed parameters as config options. In combination with a corresponding
systemd timer unit, you are able to fine tune your backup needs.
The [example section](usr/share/doc/dsnap-sync/Examples.md#systemd)
will offer details as a reference point.

* will create an appropriate local snapshot and update the metadata
* will transfer the snapshot using btrfs-send to the target device
* will create and update the snapper configuration on the target
* will update the metadata on the target device

Usualy tools will document this proccess as a disk to disk (d2d) backup.
If possible `dsnap-sync` will levarage btrfs-send capabilities to only
send deltas. It will compare the snapshot data of the ongiong process with available
snapshot data on the target device.

### Interactive backups

An interactive run will request you to select a mounted btrfs device.
You can pre-select the target drive via [command line options](https://github.com/rzerres/dsnap-sync#options).
Either use a UUID, a SUBVOLID or a TARGET name (read 'mount point').

### dsnap-sync
Beside the posix shell itself (e.g. `dash`), `dsnap-sync`relies on external
tools to achieve its goal. At run-time their availability is checked.
Following tools are used:

- awk
- btrfs
- findmnt
- sed
- snapper
- ssh / scp

As an option, you can enrich interactive responses using

- notify-send
- pv

### tape-admin

Beside the posix shell itself (e.g. `dash`), `dsnap-sync`relies on external
tools to achieve its goal. At run-time their availability is checked.
Following tools are used:

- jq
- ltfs
- mkltfs
- mtx
- perl
- sed

## Installation

### Building from source

`dsnap-sync` is a shell script. Thus no compilation is required.
To simplify correct target locations, this project uses a Makefile.

	# make install

If your system uses a non-default location for the snapper
configuration defaults, specify the location with an environment variable
(`SNAPPER_CONFIG`).

	Arch Linux/Fedora/Gentoo:
	# make SNAPPER_CONFIG=/etc/conf.d/snapper install

	Debian/Ubuntu:
	# make SNAPPER_CONFIG=/etc/default/snapper install

The local `snapper` configuration will be extended to make use
of a new template 'dsnap-sync'.

### Using distribution packages
If available, you can install `dsnap-sync` as a precompiled package.
Please use your host software package manager.

<!--
* For ARCH-Linux
[AUR package](https://aur.archlinux.org/packages/dsnap-sync)
-->

<!-- For Debian
[deb package](https://packages.debian.org/dsnap-sync). -->

<!-- For Ubuntu
[deb package](https://packages.ubuntu.org/dsnap-sync). -->

## Options

	Usage: dsnap-sync [options]

	  Options:
	  -a, --automount <path>      start automount for given path to get a valid target mountpoint.
	  -b, --backupdir <prefix>    backupdir is a relative path that will be appended to target backup-root
		  --backuptype <type>     Specify backup type <archive | child | parent>
		  --batch                 no user interaction
	  -d, --description <desc>    Change the snapper description. Default: "latest incremental backup"
		  --label-finished <desc> snapper description tagging successful jobs. Default: "dsnap-sync backup"
		  --label-running <desc>  snapper description tagging active jobs. Default: "dsnap-sync in progress"
		  --label-synced <desc>   snapper description tagging last synced jobs.
								  Default: "dsnap-sync last incremental"
		  --color                 Enable colored output messages
	  -c, --config <config>       Specify the snapper configuration to use. Otherwise will perform for each snapper
								  configuration. You can select multiple configurations
								  (e.g. -c "root" -c "home"; --config root --config home)
		  --config-postfix <name> Specify a postfix that will be appended to the destination snapper config name.
		  --dry-run               perform a trial run (no changes are written).
		  --mediapool             Specify the name of the tape MediaPool
	  -n, --noconfirm             Do not ask for confirmation for each configuration. Will still prompt for backup
		  --nonotify              Disable graphical notification (via dbus)
		  --nopv                  Disable graphical progress output (disable pv)
		  --noionice              Disable setting of I/O class and priority options on target
	  -r, --remote <address>      Send the snapshot backup to a remote machine. The snapshot will be sent via ssh
								  You should specify the remote machine's hostname or ip address. The 'root' user
								  must be permitted to login on the remote machine
	  -p, --port <port>           The remote port
	  -s, --subvolid <subvlid>    Specify the subvolume id of the mounted BTRFS subvolume to back up to. Defaults to 5.
		  --use-btrfs-quota       use btrfs-quota to calculate snapshot size
	  -u, --uuid <UUID>           Specify the UUID of the mounted BTRFS subvolume to back up to. Otherwise will prompt
								  If multiple mount points are found with the same UUID, will prompt for user selection
	  -t, --target <target>       Specify the mountpoint of the backup device
		  --volumename            Specify the name of the tape volume
	  -v, --verbose               Be verbose on what's going on (min: --verbose=1, max: --verbose=3)
		  --version		show program version

## First run

If you have never synced to the paticular target device (first run), `dsnap-sync`
will take care to create the necessary target filesystem-structure. Following
backup types are differenciated:

* btrfs-snapshots

  This is the default backup type. `dsnap-sync` will use this type to sync
  a btrfs-snapshot of an existing `snapper` configuration from a source
  device to a target device. On the target device the needed `snapper`
  structure will be build up as needed. Aside the new target filesystem
  path, `dsnap-sync` will create a new target `snapper` configuration. It
  will incorporate the template (`/etc/snapper/config-templates/dsnap-sync`).
  To garantee unique configuration names, `dsnap-sync` take the source
  configuration name and postfix it with targets hostname. You can adopt
  this behaviour with a config option (`--config-postfix`).

  The default `config-template` of dsnap-sync will inherit following
  `snapper` parameters:

  * mark new snapshots as type 'single'
  * mark new snaphosts with cleanup-algorithm 'timeline'
  * apply config option 'CONFIG_TYPE=child'
  * apply config option 'TIMELINE_CREATE=no'
  * apply config option 'TIMELINE_CLEANUP=yes'

  Please adapt the defaults, if your milage varies.

* btrfs-clone

  To duplicate an existing `snapper` configuration within a source host,
  you should use this backup type.
  It is useful, if a selected `snapper` configuration from the source
  host will be synced to a target external disk (disk-2-disk-2-disk).
  The clone configuration will be managable via `snapper` as expected.
  Please be aware, that the target device must be a btrfs filesystem
  that can save the snapshots.

* btrfs-archive

  If the target device is not a btrfs filesystem (e.g. ext4,
  xfs, ltofs tapes), you need to use this backup type.

  `dsnap-sync` will take the data of the source snapshot-ID and copy the
  data as a stream file inside ther target-subdirectory. `dsnap-sync` will
  mimic a `snapper` structure inside the 'target-subdirectory':

  * create a config specific subdirectory (`archive-<config-name>`)
  * create a snapshot-id subdirectory (`<snapper-id>`)
  * create the btrfs stream file inside the subdirectory
	  (`<snapper-id>_[full | incremental].btrfs`)
  * the proccess metadata are saved to a file called `info.xml`

  If you enabled the `ltfs` package, support for backups to tape is possible.
  ltfs will prepare a tape, than can be mounted afterwards to a selectable
  mount-point. A `dsnap-sync` backup to this path will be handeld as type
  `btrfs-archive`.

## Automounter

`dsnap-sync` offer all mounted btrfs filesystems as valid process targets.
Since storage space on disks are very price efficient this days, environments
often use removable, external disks as additional backup targets. If the
external disks aren't mounted at boot time they can't be addressed by the
selection function. It's even advisable to not mount them all the time
(e.g prevent risks for malware encryption attacks).

To link in  external disks dynamically, but also asure a persistent naming
syntax, we can use them as auto-mountable targets. To wakeup the automount
proccess before parsing available target disks, append the target mount-point
as a config option to  `dsnap-sync` (e.g: `--automount /var/backups/archive-disk1`).
The [example section](usr/share/doc/dsnap-sync/Examples.md#Automounter)
will offer details as a reference point.

## Tape-Administration / LTFS

If you use `dsnap-sync` to archive snapshots on a tape, consider to use it
in combination with LTFS. (Work in Progress: Initial support is tested
with LTO7-Tapes in a Quantum SuperLoader3).

The installation package will include a wrapper script `tape-admin`, which
implements all common tasks that are needed for tape administration.
If you are able to make use of a tape-changer (e.g Quantum SuperLoader3) the
wrapper will take advantage of the `mtx` package to handle barcodes and slot
management. If you create your own barcodes, please consult the documentation
of your Loader-Device. Most likely they do support "Code 39"-Type labels.

`LTFS` is an attempt to offer read and write-access functionality to serial
tapes in a way that's common with hard drives. From LTO5 onwards, your are
able to format/partition the tape with LTFS-Tools. After the successfull
preparation the LTFS-Tape can be mounted to a selectable mountpoint (via
FUSE). Read and write access can be managed using common OS tools.
An open-source implementation can be found at
[LinearTapeFileSystem](https://github.com/LinearTapeFileSystem/ltfs).

## Restore

### From Snapshot

When `dsnap-sync` did save the data using a native btrfs method
(`btrfs-snapshot` or `btrfs-clone`), data will be stored in a snapper compatible
directory structure on the target.

The structure may look like:

* └ backups
   * └ @\<server-name\>
	 * └ \<subvol-name\>
	   *  └ \<subvol-id\>
		 * ├ \.snapshot\>
		 * └ info.xml

To restore the data, you may either use `snapper` methods or copy back
the needed files using standard OS tools.

  * using snapper
	You may use `snapper diff <id1>..<id2> [files]` to compare the differences
	between the given suvol-id's.
	You may use `snapper rollback <id> ` to restore all data from the given \<id\>

  * using OS tools
	Use your favorit file-manager and change into the directory storing your
	target backup subvol-id. The snapshots are stored in **read-only** mode.
	Data are presented flat file and can be copied to any desired destination.

### From Tape

When `dsnap-sync` did save the data with method `btrfs-archive`, you will find
the corresponding data in a snapper compatible directory structure on the tape.

The structure may look like:

 * └ backups
   * └ @\<server-name\>
	 * └ archive-\<subvol-name\>
	   *  └ \<subvol-id\>
		 * ├ \<subvol-id\>_full.btrfs
		 * └ info.xml

The file `info.xml` provides the metadata corresponding to the snapshot.
The data of the snapshot is stored in the file `<subvol-id>_full.btrfs`.
This file has to be decrypted with btrfs tool `btrfs-send` to a btrfs
restore directory:

	cd /target_btrfs_path
	cp /path_to_tape_root/backups/@<server-name>/archive-<subvol-name>/<subvol-id>_full.btrfs .
	cat <subvol-id>_full.btrfs  | btrfs receive -v  .
	rm <subvol-id>_full.btrfs

Please consult btrfs-send man-page for further info.

## Contributing

Help is very welcome! Feel free to fork and issue a pull request to add
features or tackle open issues. If you are requesting new features, please
have a look at the TODO list. It might be already on the agenda.

## Related projects

I did fork from Wes Barnetts original work. I intend to merged it back.
Beside the fact that this version doesn't use any bashisms, Wes did let me know,
that he doesn't have the time to review the changes appropriately to make it a merge.
Anyone willing to do so is invided.

Until that date, i will offer this fork for the public. To overcome any name clashes
i renamed it to dsnap-sync.

## License

<!-- License source -->
[Logo-CC_BY]: https://i.creativecommons.org/l/by/4.0/88x31.png "Creative Common Logo"
[License-CC_BY]: https://creativecommons.org/licenses/by/4.0/legalcode "Creative Common License"

This work is licensed under a [Creative Common License 4.0][License-CC_BY]

![Creative Common Logo][Logo-CC_BY]

© 2016, 2017  James W. Barnett;
© 2017 - 2021 Ralf Zerres
