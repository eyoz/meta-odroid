# uboot-boot-scr.bbclass
#
# This provides a method to create a boot.ini or boot.scr files to help
# configure u-boot at boot up time
#
# UBOOT_FDT_FILE: default device tree. e.g., "KERNEL_DEVICETREE"
#
# UBOOT_FDT_LOADADDR: default Device tree load address, e.g., "0x01000000"
#
# UBOOT_INITRD_NAME: default initrd image name, e.g., "uInitrd"
#
# UBOOT_INITRD_ADDR: default initrd image load address, e.g., "0x2000000"
#
# UBOOT_CONSOLE: default console, e.g.,  "ttyttySAC2,115200"
#
# UBOOT_LOAD_CMD: default partition, e.g., "load"
#
# UBOOT_BOOTARGS: 
#
# UBOOT_BOOTDEV: default boot device #
#
# UBOOT_BOOTPART: default boot partition #
# 
# UBOOT_BOOTTYPE: default mmc
#
# UBOOT_ROOTDEV: default root device #
#
# UBOOT_ROOTPART: default root device #
#
# UBOOT_ROOTTYPE:  default mmcblk1p
#
# UBOOT_FILE_TITLE: default partition, e.g., "UBOOT-CONFIG"
#
# UBOOT_EXTRA_ENV: default add extra env vars , e.g., "vout,'vga'"
#
# Copyright (C) 2017, Armin Kuster <akuster808@gmail.com> 
# All Rights Reserved Released under the MIT license (see packages/COPYING)
#
inherit kernel-arch

DEPENDS += "u-boot-mkimage-native"

# enable by default
USE_BOOTSCR ?=  '1'

UBOOT_ENV_SUFFIX ??= "scr"
UBOOT_ENV ?= "boot"

UBOOT_ENV_CONFIG ?= "${B}/${UBOOT_ENV}.txt"

UBOOT_LOADADDRESS ?= ""
UBOOT_FDT_LOADADDR ?= ""
UBOOT_BOOTARGS ?= "${console} ${root} rw rootwait ${video} ${extra_cmdline}"
UBOOT_ROOT ?= "mmcblk1p2 rw rootwait"
UBOOT_KERNEL_NAME ?= ""
UBOOT_INITRD_NAME ?= ""
UBOOT_INITRD_ADDR ?= "-"

UBOOT_CONSOLE ?= ""
UBOOT_BOOTDEV  ?= "0"
UBOOT_BOOTPART ?= "1"
UBOOT_ROOTDEV ?= ""
UBOOT_ROOTPART ?= "2"
UBOOT_BOOT_CMD ?= ""

UBOOT_LOAD_CMD ?= "load"
UBOOT_EXTRA_ENV ?= ""
UBOOT_FILE_TITLE ?= "#"
UBOOT_DELAY ?= ""
UBOOT_AUTOBOOT ?= "3"
UBOOT_VIDEO ?= ""
UBOOT_XTRA_CMDLINE ?= ""
UBOOT_MULTI_BOOT ?= "1"

python create_uboot_boot_txt() {
    if d.getVar("USE_BOOTSCR") != "1":
      return

    if not d.getVar('WORKDIR'):
        bb.error("WORKDIR not defined, unable to package")

    cfile = d.getVar('UBOOT_ENV_CONFIG')
    if not cfile:
        bb.fatal('Unable to read UBOOT_ENV_CONFIG')

    localdata = bb.data.createCopy(d)

    try:
        with open(cfile, 'w') as cfgfile:

            # Title for boot.ini on some boards
            title = localdata.getVar('UBOOT_FILE_TITLE')
            if title:
                cfgfile.write('%s\n' % title)

            bootdelay = localdata.getVar('UBOOT_DELAY')
            if bootdelay:
                cfgfile.write('setenv bootdelay %s \n' % bootdelay)

            autoboot = localdata.getVar('UBOOT_AUTOBOOT')
            if autoboot:
                cfgfile.write('setenv autoboot %s \n' % autoboot)

            video = localdata.getVar('UBOOT_VIDEO')
            if video:
                cfgfile.write('setenv video \"%s\" \n' % video)

            extra_cmdline = localdata.getVar('UBOOT_XTRA_CMDLINE')
            if extra_cmdline:
                cfgfile.write('setenv  extra_cmdline \"%s\" \n' % extra_cmdline)

            console = localdata.getVar('UBOOT_CONSOLE')
            if console:
                cfgfile.write('setenv console \"%s\" \n' % console) 
           
            loadcmd = localdata.getVar('UBOOT_LOAD_CMD')

            bootdev = localdata.getVar('UBOOT_BOOTDEV')
            boottype = localdata.getVar('UBOOT_BOOTTYPE')
            bootpart = localdata.getVar('UBOOT_BOOTPART')

            rootdev = localdata.getVar('UBOOT_ROOTDEV')
            rootpart = localdata.getVar('UBOOT_ROOTPART')

            # initrd
            initrdaddr = localdata.getVar('UBOOT_INITRD_ADDR')

            initrd = localdata.getVar('UBOOT_INITRD_NAME')
            if initrd:
                cfgfile.write('setenv initrdname  \"%s\"\n' % initrd) 

            kerneladdr = localdata.getVar('UBOOT_LOADADDRESS')
            kernelname = localdata.getVar('UBOOT_KERNEL_NAME')

            fdtaddr = localdata.getVar('UBOOT_FDT_LOADADDR')
            fdtfile = os.path.basename(localdata.getVar('KERNEL_DEVICETREE'))

            imgbootcmd = localdata.getVar('UBOOT_BOOT_CMD')
            bootprefix = localdata.getVar('BOOT_PREFIX')

            uboot_extra_envs = (d.getVar('UBOOT_EXTRA_ENV') or "").split("#")
            if uboot_extra_envs:
                for e in uboot_extra_envs:
                    cfgfile.write('%s\n' % e)

            root = localdata.getVar('UBOOT_ROOT')
            cfgfile.write('setenv root \"root=/dev/%s\"\n' % root)
            bootargs = localdata.getVar('UBOOT_BOOTARGS')
            if bootargs:
                cfgfile.write('setenv bootargs \" %s \"\n' % bootargs)

            if initrd:
                cfgfile.write("%s %s %s:%s %s %s%s\n" % (loadcmd, boottype, bootdev, bootpart, initrdaddr, bootprefix, initrdname))

            if d.getVar("UBOOT_MULTI_BOOT") == "1":
                for p in range(0,3):
                    for d in range(1,3):
                        cfgfile.write("if %s %s %s:%s %s %s%s; then\n" % (loadcmd, boottype, p, d, kerneladdr, bootprefix, kernelname))
                        cfgfile.write("%s %s %s:%s %s %s%s\n" % (loadcmd, boottype, p, d, fdtaddr, bootprefix, fdtfile))
                        cfgfile.write("fi\n")

            else:
                cfgfile.write("%s %s %s:%s %s %s%s\n" % (loadcmd, boottype, bootdev, bootpart, fdtaddr,bootprefix, fdtfile))
                cfgfile.write("%s %s %s:%s %s %s%s\n" % (loadcmd, boottype, bootdev, bootpart, kerneladdr, bootprefix, kernelname))

            cfgfile.write("%s %s %s %s\n" % (imgbootcmd, kerneladdr, initrdaddr, fdtaddr))

    except OSError:
        bb.fatal('Unable to open %s' % (cfile))
}

FILES_${PN} += "/*.${UBOOT_ENV_SUFFIX}"

do_compile[prefuncs] += "create_uboot_boot_txt"

do_compile_prepend () {
    if [ "${UBOOT_ENV_SUFFIX}" = "scr" ]; then
        echo "uboot-mkimage -C none -A ${ARCH} -T script -d ${UBOOT_ENV_CONFIG} ${WORKDIR}/${UBOOT_ENV_BINARY}"
        uboot-mkimage -C none -A ${ARCH} -T script -d ${UBOOT_ENV_CONFIG} ${WORKDIR}/${UBOOT_ENV_BINARY}
    else
        cp ${UBOOT_ENV_CONFIG} ${WORKDIR}/${UBOOT_ENV_BINARY}
    fi
}

