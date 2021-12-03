# Maintainer: Ralf Zerres <ralf.zerres.de at gmail dot com>
pkgname=dsnap-sync
pkgver=0.6.6
pkgrel=1
pkgdesc="Use snapper snapshots to backup to external drive"
arch=(any)
url="https://github.com/rzerres/dsnap-sync"
license=('GPL')
depends=('btrfs-progs' 'gawk' 'dash' 'openssh' 'sed' 'snapper' 'systemd')
optdepends=('attr' 'ionice' 'jq: for "MediaPool" functionality' 'libnotify' 'ltfs' 'mtx' 'perl' 'pv' 'util-linux')
source=(${url}/releases/download/$pkgver/$pkgname-$pkgver.tar.gz{,.sig})
#validpgpkeys=('8535CEF3F3C38EE69555BF67E4B5E45AA3B8C5C3')
sha512sums=('SKIP')
	    'SKIP')

package() {
    cd $pkgname
    make SNAPPER_CONFIG=/etc/conf.d/snapper DESTDIR=$pkgdir install
}
