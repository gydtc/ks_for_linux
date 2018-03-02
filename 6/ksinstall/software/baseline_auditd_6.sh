#!/bin/bash

echo "-a exit,always -F arch=b64 -S execve -k exec" >> /etc/audit/audit.rules 
echo "-a exit,always -F arch=b32 -S execve -k exec" >> /etc/audit/audit.rules

echo "-w /etc/crontab -p wa -k crontab" >> /etc/audit/audit.rules 
echo "-w /etc/hosts -p wa -k hosts" >> /etc/audit/audit.rules 
echo "-w /etc/hosts.allow -p wa -k hosts-allow" >> /etc/audit/audit.rules 
echo "-w /etc/hosts.deny -p wa -k hosts-deny" >> /etc/audit/audit.rules 
echo "-w /etc/fstab -p wa -k fstab" >> /etc/audit/audit.rules 
echo "-w /etc/passwd -p wa -k passwd" >> /etc/audit/audit.rules 
echo "-w /etc/shadow -p wa -k shadow" >> /etc/audit/audit.rules 
echo "-w /etc/group -p wa -k group" >> /etc/audit/audit.rules 
echo "-w /etc/gshadow -p wa -k gshadow" >> /etc/audit/audit.rules 
echo "-w /etc/ntp.conf -p wa -k ntp" >> /etc/audit/audit.rules    
echo "-w /etc/sysctl.conf -p wa -k sysctl" >> /etc/audit/audit.rules 
echo "-w /etc/security/limits.conf -p wa -k limits" >> /etc/audit/audit.rules 
echo "-w /boot/grub/grub.conf -p wa -k grub" >> /etc/audit/audit.rules 
echo "-w /etc/ssh/sshd_config -p wa -k ssh" >> /etc/audit/audit.rules  
echo "-w /etc/udev/rules.d/ -p wa -k udev" >> /etc/audit/audit.rules 
echo "-w /etc/profile -p wa -k profile" >> /etc/audit/audit.rules 
echo "-w /etc/kdump.conf -p wa -k kdump" >> /etc/audit/audit.rules 
echo "-w /etc/lvm/lvm.conf -p wa -k lvm" >> /etc/audit/audit.rules
echo "-w /etc/login.defs -p wa -k login-defs" >> /etc/audit/audit.rules 
echo "-w /etc/rsyslog.conf -p wa -k rsyslog" >> /etc/audit/audit.rules 
echo "-w /etc/sysconfig/i18n -p wa -k i18n" >> /etc/audit/audit.rules 
echo "-w /etc/sysconfig/network -p wa -k network" >> /etc/audit/audit.rules
echo "-w /etc/multipath.conf -p wa -k multipath" >> /etc/audit/audit.rules

chkconfig auditd on
service auditd restart
