# dsnap-sync TODO #

## open tasks ##

- dsnap-sync: restore btrfs-streams from archive backups
  * find last full
  * iterate oval available incremental snapshots
- dsnap-sync: restore btrfs snapshot from snapshot backups
  * $ssh btrfs send `<snapshot_path>/<snapshot-id>/snapshot_ro` | btrfs receive `/<btrfs-restore-dir>/`
    (`recieved_uuid` attribte of `<btrfs-restore-dir>/snapshot_ro` will be imported from `<snapshot_path>/<snapshot-id>/snapshot_ro`)
  * btrfs sub snap `<btrfs-restore-dir>/snapshot_ro` `<btrfs-restore-dir>/snapshot_rw`
    (create a writable `snapshot_rw`; its attibute `received_uuid` isn't set anymore)
  * sub delete `<btrfs-restore-dir>/snapshot_ro`
  now you are able to mount the snapshot for further processing
- dsnap-sync: parallel tasks per config
- consider mbuffer for splitting up btrfs streams

## finished tasks ##

- dsnap-sync: refine backupdir with --interactive
- dsnap-sync: visualize backup progress (using pv)
- dsnap-sync: use snapper to administer target synced snapshots
- dsnap-sync: introduce selectable subvolid option
- dsnap-sync: refine paramteter parsing
- dsnap-sync: refine functions structure
- dsnap-sync: port as posix compatible
- dsnap-sync: introduce selectable subvolid option
- dsnap-sync: use snapper to administer target synced snapshots
- dsnap-sync: introduce snapper function: important snapshots
  Important snapshots have important=yes in the userdata
  let snapper cleanup/timeline mechanisms respect this
- tape-admin: handle common tasks for tape-changer administration
- tape-admin: handle common tasks for ltfs tape administration
- dsnap-sync: supply saving streams to tape or other filesystems
  e.g like documented in btrfs wiki
  * btrfs subvolume snapshot -r / /my/snapshot-YYYY-MM-DD && sync
  * btrfs send /my/snapshot-YYYY-MM-DD | ssh user@host 'cat >/backup/home/snapshot-YYYY-MM-DD.btrfs'
  * btrfs subvolume snapshot -r / /my/incremental-snapshot-YYYY-MM-DD && sync
  * btrfs send -p /my/snapshot-YYYY-MM-DD /my/incremental-snapshot-YYYY-MM-DD | ssh user@host 'cat >/backup/home/incremental-snapshot-YYYY-MM-DD.btrfs'
- dsnap-sync: introduce snapper config handling for parent/child types
  * disk2disk      -> parent to child on btrfs (default: snapshot)
  * disk2disk2disk -> child to child on btrfs (clone snapshot)
  * disk2disk2tape -> child to tape on non-btrfs (send btrfs-stream of snapshot if incremental, copy snapshot if first/full)


## sign new releases for github

- github: open project page
- goto releases
- download Source code (zip-file | tar.gz file) to local dir
- on local dir
  * gpg --sign-with `<secret package-signing-key id>`
    --armor
	--detach-sign dsnap-sync-`<tag>`.tar.gz
- on github: create/edit release
  * attach binaries by dropping them here or `selecting them`
  * upload signed archive (zip.asc | tar.gz.asc)
