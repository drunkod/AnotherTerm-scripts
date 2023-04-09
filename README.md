# AnotherTerm-scripts
Useful scripts for [Another Term](https://github.com/green-green-avk/AnotherTerm/wiki) local terminal.

See:
* <https://green-green-avk.github.io/AnotherTerm-docs/installing-linux-under-proot.html>
* <https://green-green-avk.github.io/AnotherTerm-docs/installing-linux-apis-emulation-for-nonrooted-android.html>
* <https://green-green-avk.github.io/AnotherTerm-docs/installing-libusb-for-nonrooted-android.html>


export ROOTFS_URL="https://gitlab.com/drunkoda/Anlinux-Resources/-/raw/main/Rootfs/Alpine/arm64/alpine-edge-rootfs.tar.xz"

./script.sh <distro> <release> [<target_subdir_name>] [-a] [-d] [-e]



alpine-minirootfs-code4.9-arm64.tar.gz

`( export ROOTFS_URL="https://gitlab.com/drunkoda/Anlinux-Resources/-/raw/main/Rootfs/Alpine/arm64/alpine-minirootfs-code4.9-arm64.tar.gz" ; S=install-linuxcontainers.sh ; "$TERMSH" copy -f -fu "https://raw.githubusercontent.com/drunkod/AnotherTerm-scripts/master/$S" -tp . && chmod 755 $S && sh ./$S -a alpine code4.9 )`

Rootfs/Alpine/arm64/alp-code-rootfs.tar.gz from https://github.com/martinussuherman/alpine-code-server/tree/master/arm64v8

`( export ROOTFS_URL="https://gitlab.com/drunkoda/Anlinux-Resources/-/raw/main/Rootfs/Alpine/arm64/alp-code-rootfs.tar.gz" ; S=install-linuxcontainers.sh ; "$TERMSH" copy -f -fu "https://raw.githubusercontent.com/drunkod/AnotherTerm-scripts/master/$S" -tp . && chmod 755 $S && sh ./$S -a alpine 3.17 )`

https://github.com/drunkod/coder-core/releases/download/20230409-212339/restreamer-rootfs.tar.gz from arm64 build
restreamer
`( export ROOTFS_URL="https://github.com/drunkod/coder-core/releases/download/20230409-212339/restreamer-rootfs.tar.gz" ; S=install-linuxcontainers.sh ; "$TERMSH" copy -f -fu "https://raw.githubusercontent.com/drunkod/AnotherTerm-scripts/master/$S" -tp . && chmod 755 $S && sh ./$S -a alpine 3.17 )`

https://github.com/drunkod/coder-core/releases/download/20230409-191432/master-rootfs.tar.gz
node js
`( export ROOTFS_URL="https://github.com/drunkod/coder-core/releases/download/20230409-191432/master-rootfs.tar.gz" ; S=install-linuxcontainers.sh ; "$TERMSH" copy -f -fu "https://raw.githubusercontent.com/drunkod/AnotherTerm-scripts/master/$S" -tp . && chmod 755 $S && sh ./$S -a alpine 3.17 )`

https://github.com/drunkod/coder-core/releases/download/20230409-203145/ffmpeg_jrottenberg-rootfs.tar.gz 

`( export ROOTFS_URL="https://github.com/drunkod/coder-core/releases/download/20230409-203145/ffmpeg_jrottenberg-rootfs.tar.gz" ; S=install-linuxcontainers.sh ; "$TERMSH" copy -f -fu "https://raw.githubusercontent.com/drunkod/AnotherTerm-scripts/master/$S" -tp . && chmod 755 $S && sh ./$S -a alpine 3.17 )`

