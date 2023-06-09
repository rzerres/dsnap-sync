# Examples

## Snapper configs cache

To integrate already existing snapshop subfolders located on a given
filesystem, you need to add the snapper config name to the config
file. Then restart the snapper service to reread the config list.

```
[root@dwsbackup dsnap-sync]# cat /etc/conf.d/snapper
## Path: System/Snapper

## Type:        string
## Default:     ""
# List of snapper configurations.

#SNAPPER_CONFIGS="root data.dwssrv1 home.dwssrv1 machines.dwssrv1 root.dwssrv1 libvirt.dwssrv1 data2.dwssrv1 lxd.dwssrv1 archiv2.dwssrv1 archiv3.dwssrv1 root.dwssrv2"
SNAPPER_CONFIGS="root data.dwssrv1"

[root@dwsbackup dsnap-snyc]# systemctl restart snapperd
```

## Automounter

`dsnap-sync` will take advantage of systemd automount units to incorporate external,
removable disks into the selection process for target devices.

### btrfs disk

Format the disk with btrfs tools to prepare it as a target.
The following example will reference to a btrfs disk and mount a given subvolume.

### systemd automount units

#### mount unit: var-backups-archive\x2ddisk1.mount

    [Unit]
    Description=Backup - Archiv-Disk 1
    Documentation=man:systemd.mount(5) man:mount.btrfs(8)
    DefaultDependencies=yes

    [Mount]
    What=UUID=977b4ecf-be67-4643-84f5-10b368c24d25
    Where=/var/backups/archive-disk1
    Type=btrfs
    Options=defaults,subvol=@archive-disk1,compress=lzo

    [Install]
    WantedBy=multi-user.target

#### automount unit: var-backups-archive\x2ddisk1.automount

    [Unit]
    Description=Automount Backup - Archive-Disk 1
    Documentation=man:systemd.automount(5)

    [Automount]
    Where=/var/backups/archive-disk1
    TimeoutIdleSec=45

    [Install]
    WantedBy=multi-user.target

## `dsnap-sync` command line usage

### backup to local target

#### Default: no selections, run for all snapper configs

    # dsnap-sync

#### Default: Select two configs, the backupdir and verbose output

    # dsnap-sync --verbose --config root --config data2 --backupdir=toshiba_r700

#### Dry-run: Select config, select Target, as batchjob (--noconfirm)

    # dsnap-sync -c root -s 265 --noconfirm --dry-run

### backup to remote target

`dsnap-sync` will rely on ssh access to the target host. For batch usage
make sure, that your public key is accepted for a remote login as user
'root'. You may have to adapt /root/.ssh/authorized_keys on the target host.

On your target host, you should also verify the availability of a
`dsnap-sync` config-template for snapper. A template `dsnap-sync`
is included in the package for your convenience.

#### Dryrun: Select remote host <ip/fqdn>, interactive, run for all configs

    dsnap-sync --dry-run --remote <fqdn/ip>
    Select target disk...
       0) /var/lib/snap-sync (uuid=b5915f47-38a8-4b37-8de6-c8b15d9aba5a,subvolid=257,subvol=/var/lib/@snap-sync)
       1) /var/backups/archive-disk4 (uuid=137b4a36-6e17-487b-a328-29b0d1e020c3,subvolid=257,subvol=/@dws-archive-disk4)
       2) /var/backups/archive-disk3 (uuid=c9fcbfd3-6a1f-4b43-8176-b6f326bf46c7,subvolid=257,subvol=/@dws-archive-disk3)
       3) /var/backups/archive-disk1 (uuid=977b4ecf-be67-4643-84f5-10b368c24d25,subvolid=257,subvol=/@dws-archive-disk1)
       4) /var/backups/archive-disk2 (uuid=b68c8a31-9878-4ec1-b7ed-948de2125285,subvolid=257,subvol=/@dws-archive-disk2)
       x) Exit
    Enter a number: 1

### Dry-run with given Target for snapper config 'data2', no confirmations

#### Sync: Select config 'data2', remote host <ip/fqdn>, target '/var/lib/snap-sync', as batchjob (--noconfirm)

    # dsnap-sync --config data2 --remote <fqdn/ip> --target /var/lib/snap-sync --batch --verbose

## dsnap-sync handling

### systemd

`dsnap-sync` will structure all scheduling tasks while using systemd units.
To perform a backup process for just a single snapper configuration at a
given time, you have to define a pair of a systemd service unit and a
corresponding systemd timer unit.

Below we define a generic `dsnap-sync service unit` that should be located
at /etc/systemd/system. Following call will reference this template:

`systemd enable dsnap-sync@data2.service`

#### service unit: `dsnap-sync@.service`

    [Unit]
    Description=dsnap-sync backup for target %i

    [Install]
    WantedBy=multi-user.target

    [Service]
    Type=simple
    ExecStart=/usr/bin/dsnap-sync \
	           --config %i \
	           --uuid 7360922b-c916-4d9f-a670-67fe0b91143c \
			   --subvolid 5 \
			   --remote backup-host
			   --batch

#### overriding service unit: `dsnap-sync@data2.service`
Please remember, that the template example encode a given target
UUID and SUBVOLID. If you want the unit to serve individual parameter,
you have to override the it like:

`systemd edit dsnap-sync@data2.service`

Define a service paragraph, clean out the ExecStart= parameter and
refine a new ExedStart= parameter with the intended.

    [Service]
    ExecStart=
    ExecStart=/usr/bin/dsnap-sync \
	           --config %i \
	           --target /var/lib/dsnap-sync \
			   --remote my-backup-host
			   --batch

#### timer unit: `dsnap-sync@.timer`

Below we define a generic `dsnap-sync timer unit` that should be located
at /etc/systemd/system.

    [Unit]
    Description=dsnap-sync weekly backup

    [Timer]
    OnCalendar=weekly
    AccuracySec=12h
    Persistent=true

    [Install]
    WantedBy=timers.target

Following call will reference this template:

`systemd enable dsnap-sync@data2.timer`


## tape-admin

## systemd

The wrapper script will enable you, to act on a parameters given as
arguments. If you want to address them regularily, you may define 
corresponding timer and service untits.

### service unit: `media-changer@.service`

This generic service template will enable a media change for a given Pool.
It should be located at /etc/systemd/system.
The media change will update the retension date for the last written tape
in that pool.

	[Unit]
	Description=dsnap-sync pool media change (Config %i)
	OnFailure=email-on-failure@%n.service
	
	[Service]
	Type=simple
	ExecStart=/usr/bin/tape-admin --media-change %i --verbose=1
	
	[Install]
	WantedBy=dsnap-sync.target

A service instance acting on a given Pool will be activated with the 
following command:

`systemd enable media-changer@Pool1.service`

### timer unit: `media-changer@.timer`

Below we define a generic `media-changer timer unit` that should be located
at /etc/systemd/system.

	[Unit]
	Description=dsnap-sync timer for media changer (config %i)
	
	[Timer]
	OnCalendar=Sat *-*-* 08:00:00
	#AccuracySec=8h
	Persistent=true
	
	[Install]
	WantedBy=timers.target

Following call will reference this template for MediaPool `Pool1` and 
activate a timer that will run the corresponding job every saturday 
at 8:00am :

`systemd enable now media-changer@Pool1.service`

#### overriding timer unit: `media-changer@Pool1.service`
Please remember, that the template example encode a default timer
used for all MediaPools. If you want the unit to serve individual parameter,
you have to override it like this:

`systemd edit media-changer@Pool1.service`

Define a Timer paragraph, clean out the parameter that should be overwritten
and refine a new one with the intended attibute.

	[Timer]
	OnCalendar=
	OnCalendar=Sat *-*-* 08:00:00

## snapper extensions

For any new `dsnap-sync` btrfs-snapshot a new target snapper structure is need,
if the target backups should be managable via snapper.

`dsnap-sync` will create this structure as needed. During the creation it
will reference to a template called `dsnap-sync`. Please adapt it
if your milage varies.

### `dsnap-sync` template

    ###
    # snapper template for dsnap-sync handling
    ###

    # subvolume to snapshot
    SUBVOLUME="/var/lib/dsnap-sync"

    # filesystem type
    FSTYPE="btrfs"


    # users and groups allowed to work with config
    ALLOW_USERS=""
    ALLOW_GROUPS="adm"

    # sync users and groups from ALLOW_USERS and ALLOW_GROUPS to .snapshots
    # directory
    SYNC_ACL="yes"


    # start comparing pre- and post-snapshot in background after creating
    # post-snapshot
    BACKGROUND_COMPARISON="yes"


    # handele NUMBER_CLEANUP via systemd, if a timer unit is active
    NUMBER_CLEANUP="yes"

    # limit for number cleanup
    NUMBER_MIN_AGE="1800"
    NUMBER_LIMIT="52"
    NUMBER_LIMIT_IMPORTANT="12"

    # handle TIMELINE via systemd, if a timer unit is active
    TIMELINE_CREATE="yes"

    # create a systemd.timer unit to handle TIMELINE cleanup
    TIMELINE_CLEANUP="yes"

    # timeline settings
    TIMELINE_MIN_AGE="1800"
    TIMELINE_LIMIT_HOURLY="1"
    TIMELINE_LIMIT_DAILY="14"
    TIMELINE_LIMIT_MONTHLY="11"
    TIMELINE_LIMIT_YEARLY="2"


    # cleanup empty pre-post-pairs
    EMPTY_PRE_POST_CLEANUP="yes"

    # limits for empty pre-post-pair cleanup
    EMPTY_PRE_POST_MIN_AGE="1800"

    # uncomment to exclude this subvol when calling
    # snap-sync as timer unit
    # SNAP_SYNC_EXCLUDE="yes"

    # Valid CONFIG_TYPE: archive, child, parent
    # CONFIG_TYPE="archive" -> if synced, stream snapshot to a non btrfs filesystem
    # CONFIG_TYPE="child"   -> if synced, stream snapshot to a given CHILD_CONFIG name
    CONFIG_TYPE="child"
    #CHILD_CONFIG=<child config name>
    #PARENT_CONFIG=<parent config name>
