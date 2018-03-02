#!/bin/bash

echo "-a exit,always -F arch=b64 -S execve -k exec" >> /etc/audit/rules.d/audit.rules 
echo "-a exit,always -F arch=b32 -S execve -k exec" >> /etc/audit/rules.d/audit.rules

echo "-w /etc/crontab -p wa -k crontab" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/hosts -p wa -k hosts" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/hosts.allow -p wa -k hosts-allow" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/hosts.deny -p wa -k hosts-deny" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/fstab -p wa -k fstab" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/passwd -p wa -k passwd" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/shadow -p wa -k shadow" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/group -p wa -k group" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/gshadow -p wa -k gshadow" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/ntp.conf -p wa -k ntp" >> /etc/audit/rules.d/audit.rules    
echo "-w /etc/sysctl.conf -p wa -k sysctl" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/security/limits.conf -p wa -k limits" >> /etc/audit/rules.d/audit.rules 
echo "-w /boot/grub/grub.conf -p wa -k grub" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/ssh/sshd_config -p wa -k ssh" >> /etc/audit/rules.d/audit.rules  
echo "-w /etc/udev/rules.d/ -p wa -k udev" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/profile -p wa -k profile" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/kdump.conf -p wa -k kdump" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/lvm/lvm.conf -p wa -k lvm" >> /etc/audit/rules.d/audit.rules
echo "-w /etc/login.defs -p wa -k login-defs" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/rsyslog.conf -p wa -k rsyslog" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/sysconfig/i18n -p wa -k i18n" >> /etc/audit/rules.d/audit.rules 
echo "-w /etc/sysconfig/network -p wa -k network" >> /etc/audit/rules.d/audit.rules
echo "-w /etc/multipath.conf -p wa -k multipath" >> /etc/audit/rules.d/audit.rules

systemctl enable auditd
service auditd restart

