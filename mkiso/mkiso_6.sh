#!/bin/bash
cd /C6/
/usr/bin/mkisofs -o /tmp/CentOS_hsyk_6.9.iso \
-b isolinux/isolinux.bin \
-c isolinux/boot.cat -no-emul-boot -boot-load-size 4 \
-boot-info-table -eltorito-alt-boot -e images/efiboot.img \
-no-emul-boot -J -R -V "CentOS6.9" /C6/

#isolinux/isolinux.cfg
#label auto
#  menu label ^Auto Install CentOS6 system
#  menu default
#  kernel vmlinuz
#  append initrd=initrd.img ks=cdrom:/ksinstall/ks/ks6.cfg

#EFI/BOOT/BOOTX64.conf 
#title CentOS 6.9 for HSYK
#        kernel /images/pxeboot/vmlinuz ks=cdrom:/ksinstall/ks/ks6.cfg
#        initrd /images/pxeboot/initrd.img