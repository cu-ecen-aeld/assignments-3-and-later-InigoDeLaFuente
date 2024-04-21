#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    echo "----------------kernel build----------------------"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig 
    make -j 4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    #make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi


# TODO: Create necessary base directories
echo "----------------Create necessary base directories----------------------"
sudo mkdir -p ${OUTDIR}/rootfs
cd "${OUTDIR}/rootfs"
sudo mkdir -p bin dev etc home lib lib64 proc sbin sys tmp user var
sudo mkdir -p usr/bin usr/lib usr/sbin
sudo mkdir -p var/log
sudo chmod -R 777 ${OUTDIR}/rootfs

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone https://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
else
    cd busybox
fi

# TODO: Make and install busybox
echo "----------------Make and install busybox----------------------"
sudo make distclean
sudo make defconfig
make CROSS_COMPILE="$CROSS_COMPILE"
make CROSS_COMPILE="$CROSS_COMPILE" CONFIG_PREFIX="${OUTDIR}/rootfs" install

echo "----------------Add library dependencies to rootfs---------------------"
echo "Library dependencies"
PROGRAM_INTERPRETER=$( ${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"| awk '{print $NF}' )
SHARED_LIBS=$( ${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"| awk '{print $NF}' )

cp /usr/local/arm-cross-compiler/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib/
cp /usr/local/arm-cross-compiler/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64/
cp /usr/local/arm-cross-compiler/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64/
cp /usr/local/arm-cross-compiler/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64/

# TODO: Make device nodes
cd "${OUTDIR}/rootfs"
echo "----------------Make device nodes---------------------"
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 1 5

# TODO: Clean and build the writer utility
echo "----------------Clean and build the writer utility---------------------"
cd /home/inigo/Desktop/course/assigments/assignments-3-and-later-InigoDeLaFuente/finder-app
sudo chmod 777 /home/inigo/Desktop/course/assigments/assignments-3-and-later-InigoDeLaFuente/finder-app
sudo make clean
make CROSS_COMPILE=${CROSS_COMPILE}
#${CROSS_COMPILE}gcc -o ${OUTDIR}/rootfs/home/writer writer.c

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
sudo cp /home/inigo/Desktop/course/assigments/assignments-3-and-later-InigoDeLaFuente/finder-app/writer.c ${OUTDIR}/rootfs/home
sudo cp /home/inigo/Desktop/course/assigments/assignments-3-and-later-InigoDeLaFuente/finder-app/writer.o ${OUTDIR}/rootfs/home
sudo cp /home/inigo/Desktop/course/assigments/assignments-3-and-later-InigoDeLaFuente/finder-app/writer ${OUTDIR}/rootfs/home

sudo cp /home/inigo/Desktop/course/assigments/assignments-3-and-later-InigoDeLaFuente/finder-app/finder.sh ${OUTDIR}/rootfs/home
sudo mkdir -p ${OUTDIR}/rootfs/home/conf
sudo cp /home/inigo/Desktop/course/assigments/assignments-3-and-later-InigoDeLaFuente/finder-app/conf/* ${OUTDIR}/rootfs/home/conf
sudo cp /home/inigo/Desktop/course/assigments/assignments-3-and-later-InigoDeLaFuente/finder-app/finder-test.sh ${OUTDIR}/rootfs/home
echo "Path reference modified."
sed -i 's|../conf/assignment.txt|conf/assignment.txt|' ${OUTDIR}/rootfs/home/finder-test.sh
sed -i '1s|^#!/bin/bash|#!/bin/sh|' ${OUTDIR}/rootfs/home/finder.sh

sudo cp /home/inigo/Desktop/course/assigments/assignments-3-and-later-InigoDeLaFuente/finder-app/autorun-qemu.sh ${OUTDIR}/rootfs/home

# TODO: Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs

# TODO: Create initramfs.cpio.gz
cd "${OUTDIR}/rootfs"

sudo find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
sudo gzip -f ${OUTDIR}/initramfs.cpio