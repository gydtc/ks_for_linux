#!/bin/bash
cd /C7
/usr/bin/mkisofs -o /tmp/CentOS_hsyk_7.4.iso \
-b isolinux/isolinux.bin \
-c isolinux/boot.cat \
-no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot \
-e images/efiboot.img -no-emul-boot -J -R -V "CentOS7" /C7/