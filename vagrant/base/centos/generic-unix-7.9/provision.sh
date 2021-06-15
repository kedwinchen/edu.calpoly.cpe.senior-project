#!/bin/bash

set -eEuo pipefail

################################################################################
# Determine where this script is stored

# Solve for the current directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

THIS_SCRIPT="${DIR}/$(basename ${0})"

printf "Using (%s) as the path of the provisioner script\n" "${THIS_SCRIPT}"

################################################################################
# Check permissions

printf "Running as %s (%s)\n" "$(whoami)" "$(id)"

if [[ $EUID -ne 0 ]] ; then
    printf "%s\n" "Attempting to elevate..."
    # re-launch as root
    exec sudo -i bash "${THIS_SCRIPT}"
fi

# this should not be able to occur
if [[ $EUID -ne 0 ]] ; then
    # at this point, we should be running as root
    # if not, then using `sudo` failed
    printf "%s\n" "Could not elevate to root"
    exit 1
else
    printf "%s\n" "Successfully elevated privileges"
fi

################################################################################
# Provisioner part

PACKAGES_TO_REMOVE=(
    "PackageKit.x86_64"
    "PackageKit.i686"
    "postfix.x86_64"
)

PACKAGES_EPEL=(
    "epel-release.noarch"
)

PACKAGES_SSSD=(
    "sssd"
    "sssd-ad"
    "sssd-client"
    "sssd-common"
    "sssd-common-pac"
    "sssd-ipa"
    "sssd-krb5"
    "sssd-krb5-common"
    "sssd-ldap"
    "sssd-proxy"
)

PACKAGES_NFS=(
    "nfs-utils.x86_64"
    "nfs4-acl-tools.x86_64"
)

PACKAGES_SAMBA=(
   "samba-client.x86_64"
   "samba-client-libs.x86_64"
   "samba-common.x86_64"
   "samba-common-libs.x86_64"
   "samba-common-tools.x86_64"
   "samba-libs.x86_64"
)

PACKAGES_YUM_BASE=(
    "sysstat"
    "openldap.x86_64"
    "openldap-devel.x86_64"
    "mpage"
    "ncurses"
    "ncurses-devel"
    "autofs.x86_64"
    "junit"
    "ldapjdk"
    "mpage"
    "gedit"
    "hardlink"
    "rdist"
    "lynx"
    "crypto-utils"
    "nscd"
    "nss-pam-ldapd"
    "pam_krb5"
    "pam_ldap"
    "avahi-ui"
    "ftp"
    "samba-winbind"
    "sgpio"
    "gnutls-devel"
    "freeglut"
    "freeglut-devel"
    "rpmdevtools"
    "rpmlint"
    "yum-plugin-tmprepo"
    "yum-plugin-versionlock"
    "setools"
    "setools-gui"
    "setools-libs"
    "expect"
    "gnome-disk-utility"
    "xterm"
    "tmux"
    "emacs-auctex"
    "gedit-plugins"
    "units"
    "git"
    "mercurial"
    "mercurial-hgk"
    "subversion-gnome"
    "qemu-kvm"
    "qemu-img"
    "qemu-kvm-tools"
    "spice-server"
    "spice-vdagent"
    "tigervnc"
    "tigervnc-server"
    "virt-what"
    "mtools"
    "screen"
    "ncdu"
    "freerdp"
    "startup-notification-devel"
    "wodim"
    "tree"
    "docbook-utils-pdf"
    "fuse-devel"
    "genisoimage"
    "openldap-clients"
    "pax"
    "squashfs-tools"
    "inkscape"
    "mesa-demos"
    "netpbm-progs"
    "SDL"
    "SDL-devel"
    "gnuplot"
    "gnuplot-latex"
    "graphviz"
    "ImageMagick"
    "xfig"
    "wireshark-gnome"
    "doxygen"
    "certmonger"
    "graphviz"
    "opencv"
    "vim"
    "python3"
    "gcc-c++"
    "autogen-libopts-devel"
    "tcsh"
    "mailx"
    "glibc-devel.i686"
    "libgcc.i686"
    "libstdc++-devel.i686"
    "man-pages"
    "man-db"
    "man"
    "man-pages-overrides"
    "libstdc++-docs"
)

PACKAGES_YUM_LIBS=(
    "libssh2"
    "libmpc"
    "libgdata-devel"
    "libpcap-devel"
    "libXau"
    "libXau-devel"
    "libXext"
    "libXi-devel"
    "libXinerama-devel"
    "libXmu"
    "libXrandr-devel"
    "libXtst-devel"
    "libbonobo-devel"
    "libgcrypt-devel"
    "libglade2-devel"
    "libgnomeui-devel"
    "libxslt-devel"
    "zlib-devel"
)

PACKAGES_MARIADB=(
    "mariadb.x86_64"
)

PACKAGES_S3CMD=(
    "s3cmd.noarch"
)

PACKAGES_JAVA=(
    "java-1.6.0-openjdk.x86_64"
    "java-1.6.0-openjdk-devel.x86_64"
    "java-1.7.0-openjdk.x86_64"
    "java-1.7.0-openjdk-devel.x86_64"
    "java-1.8.0-openjdk.x86_64"
    "java-1.8.0-openjdk-devel.x86_64"
)

PACKAGES_LIBPCAP=(
    "libpcap.x86_64"
    "libpcap.i686"
    "libpcap-devel.x86_64"
    "libpcap-devel.i686"
)

PACKAGES_VALGRIND=(
    "valgrind.x86_64"
    "valgrind.i686"
    "valgrind-devel.x86_64"
    "valgrind-devel.i686"
    "valgrind-openmpi.x86_64"
)

PACKAGES_LATEX=(
    "texlive-latex.noarch"
    "texlive-collection-latexrecommended.noarch"
)

PACKAGES_GSL=(
    "gsl.i686"
    "gsl.x86_64"
    "gsl-devel.i686"
    "gsl-devel.x86_64"
)

PACKAGES_GNUPLOT=(
    "gnuplot"
    "gnuplot-common"
    "gnuplot-doc"
    "gnuplot-latex"
)

PACKAGES_DEVELOPMENT=(
    "glm-devel.noarch"
    "glm-doc.noarch"
    "glfw.x86_64"
    "glfw-devel.x86_64"
    "pcapy.x86_64"
    "gmp.x86_64"
    "gmp-devel"
    "gcc"
    "gawk"
    "golang"
    "golang-bin"
    "tk-devel"
    "glibc-devel"
    "openmpi"
    "openmpi-devel"
    "ant"
    "cmake"
    "imake"
    "popt-devel"
    "perl-DBD-MySQL"
    "perl-DBD-SQLite"
    "postgresql-jdbc"
    "qt-mysql"
    "abrt-gui"
    "oddjob"
    "bwidget"
)

PACKAGES_AUTOJUMP=(
    "autojump.noarch"
    "autojump-zsh.noarch"
)

set -u
set +e  # allow for non-zero exit on package installation

yum upgrade -y
yum install -y @gnome-desktop @x11 @internet-browser
yum install -y "${PACKAGES_EPEL[@]}"
yum install -y "${PACKAGES_SSSD[@]}"
yum install -y "${PACKAGES_NFS[@]}"
yum install -y "${PACKAGES_SAMBA[@]}"
yum install -y "${PACKAGES_YUM_BASE[@]}"
yum install -y "${PACKAGES_YUM_LIBS[@]}"
yum install -y "${PACKAGES_MARIADB[@]}"
yum install -y "${PACKAGES_S3CMD[@]}"
yum install -y "${PACKAGES_JAVA[@]}"
yum install -y "${PACKAGES_LIBPCAP[@]}"
yum install -y "${PACKAGES_VALGRIND[@]}"
yum install -y "${PACKAGES_LATEX[@]}"
yum install -y "${PACKAGES_GSL[@]}"
yum install -y "${PACKAGES_GNUPLOT[@]}"
yum install -y "${PACKAGES_DEVELOPMENT[@]}"
yum install -y "${PACKAGES_AUTOJUMP[@]}"
yum erase -y "${PACKAGES_TO_REMOVE[@]}"

yum install -y openconnect

cd /bin
wget https://gitlab.com/kedwinchen/edu.calpoly.cpe.senior-project/-/raw/latest-release/vagrant/scripts/handin-to-unix/handin
chown root:root handin
chmod 6555 handin
chcon system_u:object_r:bin_t /bin/handin

# disable SELinux (yeah yeah it's not secure, but it's also disabled on the UNIX servers so... this is to match it)
sed -i 's/^SELINUX=.*$/SELINUX=disabled/g' /etc/selinux/config

# remove cached packages
yum clean all

# clean up logs
find /var/log -type f -exec truncate -s 0 {} \;
# rm -rvf /var/log/*

# set to boot to graphical desktop
systemctl enable gdm.service
systemctl set-default graphical.target

set +u
