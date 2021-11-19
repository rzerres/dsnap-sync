<!-- dsnap-sync README.md -->
<!-- version: 0.6.6 -->

# dsnap-sync

<p align="center">
  <span>English</span> |
  <a href="../..">Englisch</a>
  <!-- a href="../spanish">Spanisch</a> | -->
</p>

## Über

`dsnap-sync` ist konzipiert, um Backups für btrfs formatierte Dateisysteme
durchzuführen. Es bedient sich der von btrfs bereitgestellten Snapshot
Funktionalität und kombiniert diese mit den Management-Funktionen von
`snapper`.

`dsnap-sync` erstellt die Sicherungen als btrfs-Snapshots auf einem Ziel-Gerät.
Hierzu muss das Gerät zunächst formatiert und anschließend im Betriebssystem
bereitgestellt werden. Das unterstützte Ziel-Medium ist entweder
eine USB Festplatte, ein automatisch eingelinktes RAID System, oder ein LTFS
formatiertes Band. Alle unterstützten Ziel-Geräte können sich auch auf einem
einem entfernten Host befinden.
Wenn möglich wird der Sicherungs-Prozess nur die inkrementellen Veränderungen
im Snapshot auf das Ziel-Gerät übertragen. Bei Sicherungen auf einem entfernten
Host wird die Übertragung mittels ssh gesichert.

Mit Blick auf Portabilität und Ressourcen-Schonung wurde `dsnap-sync`als Posix
Shell Script implementiert (dash). Es unterstützt sowohl interaktive als auch
zeitgesteuerte Sicherungs-Prozesse. Zeitgesteuerte Sicherungen sollten als
systemd Einheiten (service- und timer-units) implementiert werden.
Für Details wird auf den [Beispiel-Abschnitt](../../usr/share/doc/dsnap-sync/Examples.md#systemd)
verweisen.

## Sicherungs-Prozess

Für einen Sicherungs-Prozess wird `dsnap-sync` in der Standardkonfiguration
alle definierten `snapper` Konfigurationen des Quell-Systems einbeziehen.
Wenn Sie es vorziehen, individuelle Sicherungs-Prozesse je `snapper` Konfiguration
oder Konfigurations-Gruppen einzurichten, sollten sie eigenständige systemd units
definieren. Diese können anschließend interaktiv oder über timer units
aufgerufen werden.
`dsnap-sync` wird alle refenzierten `snapper` Konfigurationen im Sicherungslauf
berücksichtigen (Option: `-c` oder `--config`).

Für jede ausgewählte `snapper` Konfiguration wird `dsnap-sync`

* die Ziel-Geräte Informationen anzeigen/auswählen
* die snapper Strukturen vorbereiten
* die eigentliche Sicherung ausführen
  (Verarbeitung für backupdir, snapper Strukturen, btrfs send / btrfs recieve)
* abschließende Sicherungs-Arbeiten ausführen
  (Aktualisierung der snapper Metadata für jeden Quell- und Ziel-Snapshot)
* abschließende Aufräumarbeiten durchführen

Üblicherweise beschreiben artverwandte Tools diesen Prozess als
Disk to Disk (d2d) Sicherung. Wenn möglich wird `dsnap-sync` die
`btrfs send / btrfs recieve` Funktionen nutzen, um nur Veränderungen des
Snapshots zur übertragen. Dabei vergleicht es Snapshot-Daten des Quell
Systems mit Snapshot-Daten des Ziel Systems. Existiert eine gemeinsame
Snapshot-ID auf beiden Systemen, wird `dsnap-sync` die
`btrfs send / btrfs receive` Pipe vorbereiten und die Daten transferieren.
Im Vergleich zu einer klassischen Voll-Sicherung verkürzt dies die
benötigte Übertragungszeit erheblich.

### Interaktive Sicherungen

Ein interkativer Sicherungsprozess wird Ihnen die Auswahl eines
Ziel-Gerätes anbieten. Sie können dieses Ziel-Gerät mit
[Kommando-Zeilen Parametern](./README.md#Optionen) vorauswählen.
Um eine eindeutige Zuordung eines Ziel-Gerätes sicherzustellen,
müssen sie entweder

* ein Paar aus btrfs UUID und SUBVOLID
* ein Target (hier: 'mount point')
* ein MediaPool / Band-Name

auswählen. Damit ist `dsnap-sync` in der Lage Sicherungsprozesse zu
unterscheiden, die als Quelle den gleichen Snapshot haben, jedoch
auf unterschiedliche Ziele gesichert werden sollen. Als Beispiel sei
angeführt, dass Projektdaten redundant auf voneinander unabhängige
Ziel-Medien (Festplatten, Bänder) gesichert werden müssen.

Bevor `dsnap-sync` das eigentliche Backup durchführt, wird es Ihnen
die Möglichkeit anbieten, einen Backup-Pfad (backudir) auszuwählen.
Darüber hinaus werden Quell und Ziel Informationen ausgewiesen.
Sie können die Aufforderung zur Bestätigung der Parameter über
Kommandozeilen-Parameter unterdrücken (z.B --noconfirm, --batch).

### Zeitgesteuerte Sicherungen

Eine zeitliche Steuerung von Sicherungs-Prozessen sollte über
systemd-units definiert werden. Innerhalb der systemd.service
Definition wird in der [Service] Sektion der ExecStart Parameter
als `dsnap-sync` Aufruf mit allen gewünschten Optionen eingestellt.
In Verbindung mit einer zugehörigen systemd.timer Definition sind
sie in der Lage, unterschiedliche Ausführungszeiten mit selektierten
Optionen umzusetzen. Für Details wird auf den
[Beispiel-Abschnitt](../../usr/share/doc/dsnap-sync/Examples.md#systemd)
verweisen.

## Anforderungen

### dsnap-sync

Neben der eigentlichen Posix Shell (e.g. `dash`), bedient sich
`dsnap-sync` externer Tools, um die gewünschte Funktionalität
bereitzustellen. Deren Verfügbarkeit wird zur Laufzeit überprüft.
Folgende Tools werden verwendet:

- awk
- btrfs
- findmnt
- sed
- snapper
- ssh / scp

Optional können interaktive Rückmeldungen mit foldenen Tools ergänzt
werden:

- notify-send
- pv

### tape-admin

Neben der eigentlichen Posix Shell (e.g. `dash`), bedient sich
`tape-admin` externer Tools, um die gewünschte Funktionalität
bereitzustellen. Deren Verfügbarkeit wird zur Laufzeit überprüft.
Folgende Tools werden verwendet:

- jq
- ltfs
- mkltfs
- mtx
- perl
- sed

## Installation

### Aus den Quellen

`dsnap-sync` ist ein Shell Script. Daher ist keine Kompilierung
erforderlich. Über ein Makefile wird die Installation an den
richtigen Ziel-Pfad gesteuert.

	# make install

Sollte Ihr System einen unüblichen Speicherort für die snapper
Konfigurationen verwenden, kann der Pfad in einer Umgebungs-Variable
für die Installation einbezogen werden (`SNAPPER_CONFIG`).

	Arch Linux/Fedora/Gentoo:
	# make SNAPPER_CONFIG=/etc/conf.d/snapper install

	Debian/Ubuntu:
	# make SNAPPER_CONFIG=/etc/default/snapper install

Die lokalen `snapper` Konfiguration werden um ein neues Template
'dsnap-sync' ergänzt.

### Verwendung eines Distributions-Pakets

Wenn verfügbar können sie `dsnap-sync` als vorkonfiguriertes Paket
installieren. Bitte verwenden sie hierzu den Betriebssystem eigenen
Software Paket Manager.

<!--
* For ARCH-Linux
[AUR package](https://aur.archlinux.org/packages/dsnap-sync)
-->

<!-- For Debian
[deb package](https://packages.debian.org/dsnap-sync). -->

<!-- For Ubuntu
[deb package](https://packages.ubuntu.org/dsnap-sync). -->

## Optionen

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

## Erster Sicherungslauf

Haben Sie bisher noch niemals auf ein Ziel-Gerät gesichert (first run), wird
`dsnap-sync` für die Erstellung der notwendigen Ziel Dateisystem-Strukturen
sorgen. Folgende Sicherungstypen werden unterschieden:

* btrfs-snapshots

  Dieser Sicherungstyp ist der Systemstandard. Bei einem btrfs-snapshot
  wird `dsnap-sync` verwendet, um bestehende `snapper` Konfigurationen
  der Quelle auf ein Ziel-Gerät zu synchronisieren.
  Auf dem Ziel-Gerät wird eine `snapper` Struktur falls erforderlich
  neu erstellt. Dies beinhaltet die Erstellung von Ziel-Dateisystem Pfaden,
  als auch die Erstellung der snapper Konfiguraktion unter Verwendung eines
  Templates (`/etc/snapper/config-templates/dsnap-sync`).
  Um eindeutige Namen bei der Nutzung von Konfiguration sicherzustellen,
  wird `dsnap-sync` den Host-Namen des Quell-Systems an den Konfigurationsname
  auf dem Ziel-System anhängen. Sie können dieses Verhalten durch eine
  Konfigurations-Option anpassen (`--config-postfix`).

  Folgende Parameter werden vom Template `dsnap-sync` an die aktive
  Konfiguration vererbt:

  * Neue Snapshots als Type 'single' markieren
  * Neue Snapshots mit dem Clean-Algorithmus 'timeline' markieren
  * die Konfigurationsoption 'CONFIG-TYPE=child' setzen
  * die Konfigurationsoption 'TIMELINE_CREATE=no' setzen
  * die Konfigurationsoption 'TIMELINE_CLEANUP=yes' setzen

  Bitte passen sie diese Einstellungen auf Ihre Bedürfnisse an.

* btrfs-clone

  Dieser Sicherungstyp ermöglicht die Duplizierung einer bereits
  existierenden `snapper` Konfiguration innerhalb eines Quell-Systems.
  Sinnvoll ist dies Funktionalität, wenn die auf dem Quell-System
  die gewählte `snapper` Konfiguration auf externe Festplatten archiviert
  werden sollen (disk-2-disk-2-disk). Auch diese Clone-Konfiguration
  kann anschließend über die `snapper` Management-Tools verwaltet
  werden. Das Ziel-Gerät muss daher zwingend ein btrfs Dateisystem
  bereitstellen.

* btrfs-archive

  Stellt das Ziel-Gerät kein btrfs Dateisystem bereit (e.g. ext4, xfs,
  ltofs tapes), kann der Sicherungstyp btrfs-archive angewendet werden.

  `dsnap-sync` wird anhand der Quell Snapshot-ID die Daten in ein
  gewöhnliches Unterverzeichnis kopieren. Dieses Stamm-Verzeichnis
  befindet sich unterhalb des Backup-Verzeichnisses auf dem Ziel-Gerät
  (target-subdirectory). Unterhalb des 'target-subdirectory' erstellt
  `dsnap-sync` in Analogie zur `snapper` Datenablabe folgende Struktur:

  * ein Unterverzeichnis des Konfigurations-Namens (`archive-<config-name>`)
  * ein Unterverzeichnis der Snapshot-ID (`<snapper-id>`)
  * der aktuelle btrfs Stream wird im Unterverzeichnis abgelegt
	(`<snapper-id>_[full | incremental].btrfs`)
  * die Metadaten des Prozesses werden in der Datei `info.xml` abgelegt

  Steht `ltfs` zur Verfügung, ist ein Backup auf Bänder möglich.
  Hierbei wird ein Band durch ltfs vorbereitet und kann anschließend in
  das Dateisystem unter einem definierten Pfad eingebunden werden
  ('mount-point'). Eine `dsnap-sync` Sicherung auf diesen Pfad erfolgt
  über den Sicherungstyp `btrfs-archive`.

## Automounter

`dsnap-sync` stellt alle verwendbaren btrfs Dateisysteme als Prozess-
Ziele bereit. Da Festplatten mit großen Speicher-Kapazitäten heutzutage
sehr preiswert angeboten werden, sind externe Festplatten als zusätzliche
Sicherungsziele üblich. Werden dies externen Festplatten aber nicht
während des Boot-Prozesses oder über dynamische Regeln eingebunden,
können sie von `dsnap-sync` nicht in der Auswahl-Funktion angeboten senden.
Es ist darüber hinaus durchaus sinnvoll, solche Festplatten nicht permanent
einzubinden (z.B. um die Risiken eines Malware-Angriffs zu minimieren, der
erreichbare Pfade verschlüsselt.)

Um externe Festplatten dynamisch mit einer persistenten Namens Syntax
einzubinden, können sie als 'automountbare Geräte' definiert werden.
Aktiviert wird der Automount-Prozess vor der Ziel-Auswahl zu aktivieren,
kannn der 'Mount-Point' als Option beim `dsnap-sync` Aufruf übergeben
werden (z.B: `--automount /var/backups/archive-disk1`).
Der [Abschnitt Automount](../../usr/share/doc/dsnap-sync/Examples.md#Automounter)
des Beispiel Dokuments enthält weitere Details.

## Tape-Administration / LTFS

Wenn sie `dsnap-sync` für die Archivierung von Snapshots auf Bänder
verwenden, sollten den Einsatz in Kombination mit LTFS überdenken.
(WIP - work in progress: Die erster erfolgreicher Versuch wurde mit
LTO7-Bändern in einem Quantum SuperLoader3 getestet).

Das Installations-Paket beinhaltet ein Hilfs-Skript `tape-admin`, das
alle Basisaufgaben für die Administration von Bändern als Funktionen
bereitstellt. Hardware, die einen mechanischen Bandwechsel ermöglicht
(z.B Quantum SuperLoader3), kann das Hilfs-Skript über das Paket `mtx`
steuern. Dies beinhaltet das Auslesen von Barcodes als auch das Laden
und Entladen von Bändern in wählbare Quell- und Ziel-Schächte (Slots).

(WIP: Die Zuordnung von Band-Namen zu Pools und Slots neben deren
Media-Zugriffsrichtlienen wird in einer JSON-Datei beschrieben.
Diese muss derzeit noch manuell gepflegt werden:
`/etc/dsnap-sync/MediaPools.json`).

Werden Barcode-Labels selbst erstellt, prüfen Sie bitte Hinweise auf das
zu verwendende Format. Üblicherweise unterstützen die Barcode-Leser
"Code 39" Etiketten.

`LTFS` ist ein Ansatz, der Lese- und Schreib-Operationen auf Bänder in
der für Festplatten üblichen Funktionsweise implementiert. Ab Geräten
der LTO5 Generation sind Sie in der Lage, Bänder für die LTFS-Nutzung
vorzubareiten (formatieren, bzw. partitionieren).
Anschließend können erfolgreich formatierte Bänder in das Dateisystem
eingehängt werden (FUSE). Das Beschreiben und Auslesen der Daten erfolgt
dann mit den gewohnten Betriebssystem Tools. Eine Open-Source Implementierung
finden Sie z.B. unter
[LinearTapeFileSystem](https://github.com/LinearTapeFileSystem/ltfs).

## Rücksicherung (restore)

### Dateisystem (target)

Wurden Daten mit einer nativen btrfs Methode (`btrfs-snapshot`,
`btrfs-clone`) gesichert, befinden sie sich in einer `snapper` kompatiblen
Verzeichnisstruktur auf dem gewählten Target.

Diese Struktur könnte so aussehen:

* └ backups
   * └ @\<server-name\>
	 * └ \<subvol-name\>
	   *  └ \<subvol-id\>
		 * ├ \.snapshot\>
		 * └ info.xml

Um Daten zurückzusichern, können Sie entweder native `snapper` Methoden verwenden,
oder auf Betriebssystem Programme zurückgreifen.

  * native snapper Methoden

	Verwenden Sie `snapper diff <id1>..<id2> [Dateien]`, um Unterschiede in den
	gewählten subvol-id's aufzuzeigen.
	Verwenden Sie `snapper rollback <id>`, um alle Daten der Sicherung (\<subvol-id\>)
	an den Ursprungsort zurückzusichern.

  * Betriebssystem Programme

	Verwenden Sie Ihren bevorzugten  Datei-Manager und wechseln Sie in das
	Verzeichnis, in dem sich die Daten des gewünschten Backups (\<subvol-id\>)
	befinden. Die Daten wurden als **read-only** Snapshot gesichert.
	Sie können von hier aus in jedes gewünsche Zielverzeichnis kopiert werden.

### Band-Sicherung (tape)

Wurden Daten mit der Methode `btrfs-archive` gesichert, speichert `dsnap-sync`
diese in einer `snapper` kompatiblen Datei-Struktur auf dem Band.

Dies Struktur könnte so aussehen:

 * └ backups
   * └ @\<server-name\>
	 * └ archive-\<subvol-name\>
	   *  └ \<subvol-id\>
		 * ├ \<subvol-id\>_full.btrfs
		 * └ info.xml

In der Datei `info.xml` werden die Metadaten zum Snapshot gespeichert.
Die Bewegungsdaten des snapshots befinden sich in der Datei `\<subvol-id\>_full.btrfs`.
Diese Datei muss mit dem btrfs programm `btrfs-send` auf ein btrfs Verzeichnis zurück
geschrieben werden:

	cd /target_btrfs_path
	cp /path_to_tape_root/backups/@<server-name>/archive-<subvol-name>/<subvol-id>_full.btrfs .
	cat <subvol-id>_full.btrfs  | btrfs receive -v  .
	rm <subvol-id>_full.btrfs

Die man-page zu `btrfs-send` enthält weiterführende Informationen.

## Mitarbeit

Hilfe ist sehr willkommen! Gerne könnt Ihr das Projekt forken und PR's einreichen,
um neue Funktion zu implementieren oder Fehler zu bereinigen.
Wenn Ihr an neuen Funktionen arbeiten wollt, schaut bitte auch in das TODO Dokument.
Vielleicht findet Ihr dort auch Anregungen.

## Ähnliche Projekte

`dsnap-sync` basiert auf dem ursprünglichen Code von Wes Barnetts. Als
open-source war meine Intention, die Erweiterungen in das Projekt
zurückfliessen zu lassen. Neben der Tatsache, dass diese Version bashisms
eleminiert hat, sieht Wes sich leider zeitlich ausser Stande, den neuen
Code in angemessener Art und Weise zu prüfen um ihn anschließende in
`snap-sync` einzubinden. Jeder ist willkommen dies zu tun.

Bis dahin habe ich mich entschlossen, die Ergebnisse als Fork unter dem
Namen `dsnap-sync` zu veröffentlichen. Die Namensämderung soll mögliche
Verwechslungen vermeinden.

## Lizenz

<!-- License source -->
[Logo-CC_BY]: https://i.creativecommons.org/l/by/4.0/88x31.png "Creative Common Logo"
[License-CC_BY]: https://creativecommons.org/licenses/by/4.0/legalcode "Creative Common License"

Diese Arbeit ist unter der [Creative Common License 4.0][License-CC_BY] lizensiert.

![Creative Common Logo][Logo-CC_BY]

© 2016, 2017  James W. Barnett;
© 2017 - 2021 Ralf Zerres
