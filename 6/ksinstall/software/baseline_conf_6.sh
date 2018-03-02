#!/usr/bin/env bash
#
#2018/03/01

function usage()
{
    cat << EOF
    usage: $0 options
 
    OPTIONS:
        help     Show this message
        check    Only check the configuration, but will not change!
        conf     Automately change all configuration to user defined!
EOF
}


case $1 in
     help)
         usage
         exit 1
         ;;
     check)
         AUTOFIX=0
         ;;
     conf)
         AUTOFIX=1
         ;;
     *)
         usage
         exit 1
         ;;
esac

if [ -f /etc/redhat-release ]; then
OSVERSION=`awk '{ print $(NF-1) }' /etc/redhat-release  |awk -F"." '{print $1}'`
    if [ "$OSVERSION" -ne 6 ]; then
      echo -e "[31mPlease check whether the OS version is RHEL6!!![0m"
      exit 1
    fi
else
    echo -e "[31mPlease check whether the OS version is RHEL6!!![0m"
    exit 1
fi

CHECKTOTAL=0
CHECKFAILED=0
CHECKERROR=0

function add_check_item_total
{
        CHECKTOTAL=$[CHECKTOTAL+1]
}
function add_check_item_failed
{
        [ $CHECKERROR -ne 0 ] && CHECKFAILED=$[CHECKFAILED+1]
}
function add_check_item_error
{
        CHECKERROR=$[CHECKERROR+1]
}

echo ""
echo "[1;32m  Starting Checking System configuration [0m"
echo ""
#Configure password policies
echo -e "[1mChecking password validity starting ...[0m"
CHECKERROR=0
value=`gawk '/^ *PASS_MAX_DAYS/{print $2}' /etc/login.defs`
if [ $value != 90 ]; then
        echo -e "\t[31mPASS_MAX_DAYS is not 90 !!![0m" 
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && sed -ri "/^ *PASS_MAX_DAYS */c PASS_MAX_DAYS 90" /etc/login.defs && echo -e "\t[32m==>fixed[0m"
fi

value=`gawk '/^ *PASS_MIN_DAYS/{print $2}' /etc/login.defs`
if [ $value != 2 ]; then
        echo -e "\t[31mPASS_MIN_DAYS is not 2 !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && sed -ri "/^ *PASS_MIN_DAYS */c PASS_MIN_DAYS 2" /etc/login.defs && echo -e "\t[32m==>fixed[0m"
fi


value=`gawk '/^ *PASS_MIN_LEN/{print $2}' /etc/login.defs`
if [ $value != 8 ]; then
        echo -e "\t[31mPASS_MIN_LEN is not 8 !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && sed -ri "/^ *PASS_MIN_LEN */c PASS_MIN_LEN 8" /etc/login.defs && echo -e "\t[32m==>fixed[0m"
fi

value=`gawk '/^ *PASS_WARN_AGE/{print $2}' /etc/login.defs`
if [ $value != 7 ]; then
        echo -e "\t[31mPASS_WARN_AGE is not 7 !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] &&  sed -ri "/^ *PASS_WARN_AGE */c PASS_WARN_AGE 7" /etc/login.defs && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking password validity done ![0m"
add_check_item_total
add_check_item_failed
echo ""

echo -e "[1mChecking password complexity starting ...[0m"
CHECKERROR=0
value=`gawk -F"pam_cracklib.so" '/pam_cracklib/{print  $2}' /etc/pam.d/system-auth-ac `
new_val=`grep 'try_first_pass retry=3 minlen=8 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1' /etc/pam.d/system-auth-ac `
if [ $? != 0 ]; then
        echo -e "\t[31mpam_cracklib.so config: $value !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] &&  sed -i "s/^password    requisite     pam_cracklib.so try_first_pass.*/password    requisite     pam_cracklib.so try_first_pass retry=3 minlen=8 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1/g" /etc/pam.d/system-auth-ac  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking password complexity done ![0m"
add_check_item_total
add_check_item_failed
echo ""


echo -e "[1mChecking password multiplexing starting ...[0m"
CHECKERROR=0
value=`grep 'sha512 shadow nullok try_first_pass use_authtok remember=5' /etc/pam.d/system-auth-ac `
if [ $? != 0 ]; then
        echo -e "\t[31mpam_unix.so config remember is not 5 !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && sed -i '/password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok$/s/$/ remember=5/' /etc/pam.d/system-auth-ac  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking password multiplexing done ![0m"
add_check_item_total
add_check_item_failed
echo ""


echo -e "[1mChecking password locking starting ...[0m"
CHECKERROR=0
value=`grep 'onerr=fail deny=6 unlock_time=300' /etc/pam.d/system-auth-ac `
if [ $? != 0 ]; then
        echo -e "\t[31mpam_tally2.so unlock_time is not config !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && sed -i "/# User/aauth        required      pam_tally2.so onerr=fail deny=6 unlock_time=300" /etc/pam.d/system-auth-ac && sed -i "/# User/aauth        required      pam_tally2.so onerr=fail deny=6 unlock_time=300" /etc/pam.d/password-auth-ac  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking password locking done ![0m"
add_check_item_total
add_check_item_failed
echo ""

#Check USERS
echo -e "[1mChecking non root user with UID 0 ...[0m"
CHECKERROR=0
value=`awk -F: '($3 == 0) { print $1 }' /etc/passwd |grep -v root`
        if [  -n "$value" ]; then
                for user in $value
                do
                echo -e "\t[31mUID 0 user is: $user !!![0m"
                add_check_item_error
                [ $AUTOFIX -ne 0 ] && /usr/sbin/usermod -L $user --force >/dev/null 2>&1   && echo -e "\t[32m==>fixed[0m"
                done
        fi

echo "[1mChecking non root user with UID 0  done ! [0m"
add_check_item_total
add_check_item_failed
echo ""

echo "[1mChecking User's emptypasswords  starting ...[0m"
CHECKERROR=0
value=`awk -F: '($2 == "") { print $1 }' /etc/shadow`
        if [  -n "$value" ]; then
                for user in $value
                do
                echo -e "\t[31mEmptypassword user is: $user !!![0m"
                add_check_item_error
                [ $AUTOFIX -ne 0 ] && /usr/sbin/usermod -L $user  && echo -e "\t[32m==>fixed[0m"
                done
        fi

echo "[1mChecking User's emptypasswords  done ! [0m"
add_check_item_total
add_check_item_failed
echo ""

# Set User's passwd be expired
echo "[1mChecking User's passwd should be expired starting ...[0m"
CHECKERROR=0
for NAME in `cut -d: -f1 /etc/passwd`
    do
        MyUID=`id -u $NAME`
        if [ $MyUID -ge 500 -a $NAME != 'nfsnobody' -a $NAME != 'admin' ]; then
             value=`chage -l $NAME 2>/dev/null | egrep  "Maximum" | awk -F: '{print $2}'`
             if [ $value  != "90" ] ; then
                echo -e "\t[31mUser $NAME not have the limited expire peirod[0m" 
                add_check_item_error
                [ $AUTOFIX -ne 0 ] && chage -m 1 -M 90 -W 7 $NAME -d `date '+%Y-%m-%d'` && echo -e "\t[32m==>fixed[0m"
             fi
        fi
done
echo "[1mChecking User's passwd expire peirod done ! [0m"
add_check_item_total
add_check_item_failed
echo ""

# Set User's passwd not be expired
echo "[1mChecking User's passwd should not be expired starting ...[0m"
CHECKERROR=0
function passwd_not_expired
{
        value=`chage -l $1 2>/dev/null`
        if [ $? -ne 0 ]; then
        	echo -e "\t[31mNo user : $1 [0m"
                add_check_item_error
                return
        else
                value=`chage -l $1 2>/dev/null | egrep  "Password expires" | awk '{print $4}'`
                if [ $value  != "never" ] ; then
                   echo -e "\t[31mUser $1 not have the unlimited expire peirod [0m" 
                   add_check_item_error
                   [ $AUTOFIX -ne 0 ] && chage -E -1 -M -1 $1 && echo -e "\t[32m==>fixed[0m"
                fi
        fi
}
passwd_not_expired root
echo "[1mChecking User's passwd expire peirod done ! [0m"
add_check_item_total
add_check_item_failed
echo ""

#lock Login of System Accounts
echo "[1mChecking system accounts starting ...[0m"
CHECKERROR=0
for NAME in `cut -d: -f1 /etc/passwd`
    do
        MyUID=`id -u $NAME`
        value=`/usr/bin/passwd -S "$NAME" 2>/dev/null |grep "in use"` 
        ulock=$?
        if [ $MyUID -lt 500 -a $NAME != 'root' -a $ulock -eq 0 ]; then
            echo -e "\t[31mUser: $NAME   \tis a system account, but not Locked it [0m"
            add_check_item_error
            [ $AUTOFIX -ne 0 ] && usermod -L -s /dev/null $NAME && echo -e "\t[32m==>fixed[0m" 
        fi
done
    [ $AUTOFIX -ne 0 ] && usermod -L -s /dev/null nfsnobody > /dev/null 2>&1
echo "[1mChecking system accounts done ![0m"
add_check_item_total
add_check_item_failed
echo ""

# Check service is exsit or stopped
echo "[1mChecking any forbid services starting ...[0m"
CHECKERROR=0
for service in NetworkManager acpid autofs bluetooth cups dnsmasq firstboot iptables ip6tables postfix sendmail postgresql pppoe-server pcscd smb httpd  squid smartd spice-vdagentd rhnsd rhsmcertd wpa_supplicant winbind ypbind xinetd
do
value1=`service $service status 2>/dev/null`
returnval=$?
value2=`/sbin/chkconfig --list $service 2>/dev/null | grep -w -q on`
switch=$?
if [ $returnval -eq 0  -o  $switch -eq 0  ]; then
     echo -e "\t[31mservice :\t$service    \tis\trunning,[0m"
     add_check_item_error
   if [ $AUTOFIX -ne 0 ]; then
        /sbin/chkconfig --level 2345 $service off >/dev/null 2>&1
        /sbin/service $service  stop >/dev/null 2>&1  && echo -e "\t[32m==>fixed[0m"
   fi
fi
done
echo "[1mChecking any forbid services done ! [0m"
add_check_item_total
add_check_item_failed
echo ""

#Check /etc/profile 
echo "[1mChecking histtimeformat starting ...[0m"
CHECKERROR=0
value=`grep 'HISTTIMEFORMAT=' /etc/profile.d/myhistory.sh`
if [ $? != 0 ]; then
        echo -e "\t[31mHISTTIMEFORMAT is not config !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && echo "export HISTTIMEFORMAT=\"%F %T \"" >> /etc/profile.d/myhistory.sh  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking histimeformat done ![0m "
add_check_item_total
add_check_item_failed
echo ""

echo "[1mChecking prompt_command starting ...[0m"
CHECKERROR=0
value=`grep 'PROMPT_COMMAND=' /etc/profile.d/myhistory.sh`
if [ $? != 0 ]; then
        echo -e "\t[31mPROMPT_COMMAND is not config !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && echo "export PROMPT_COMMAND=\"history -a\"" >> /etc/profile.d/myhistory.sh  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking prompt_command done ![0m "
add_check_item_total
add_check_item_failed
echo ""

echo "[1mChecking histcontrol starting ...[0m"
CHECKERROR=0
value=`grep '^export HISTCONTROL' /etc/profile.d/myhistory.sh`
if [ $? != 0 ]; then
        echo -e "\t[31mHISTCONTROL is not config !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && echo "export HISTCONTROL=\"ignoredups\"" >> /etc/profile.d/myhistory.sh  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking histcontrol done ![0m "
add_check_item_total
add_check_item_failed
echo ""

echo "[1mChecking histsize starting ...[0m"
CHECKERROR=0
value=`grep '^HISTSIZE' /etc/profile.d/myhistory.sh |gawk -F'=' '{print $2 }'`
if [ $value != 2000 ]; then
        echo -e "\t[31mHISTSIZE config is: $value !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && echo "export HISTSIZE=2000" >> /etc/profile.d/myhistory.sh && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking histsize done ![0m "
add_check_item_total
add_check_item_failed
echo ""

echo "[1mChecking timeout starting ...[0m"
CHECKERROR=0
value=`grep  "export TMOUT=600" /etc/profile.d/mytimeout.sh `
if [ $? != 0 ]; then
        echo -e "\t[31mTimeOut is not config !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && echo "export TMOUT=600" >> /etc/profile.d/mytimeout.sh  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking timeout done ![0m "
add_check_item_total
add_check_item_failed
echo ""

# Check umask value
echo "[1mChecking umask value starting ...[0m"
CHECKERROR=0
value=`grep 'umask 0' /etc/profile |gawk '{print $2 }' |tail -n1 2>/dev/null `
if [ $value != "027" ]; then
    echo -e "\t[31mIncorrect umask value : $value[0m" 
    add_check_item_error
    [ $AUTOFIX -ne 0 ] && sed -i 's/umask 0.*/umask 027/g' /etc/profile && sed -i 's/umask 0.*/umask 027/g' /etc/bashrc  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking umask value done ![0m"
add_check_item_total
add_check_item_failed
echo ""

#Check disable usb storage
echo "[1mChecking usb-storage disable starting ...[0m"
CHECKERROR=0
if [ -f /etc/modprobe.d/usb-storage.conf ]; then
value=`grep "^install usb-storage /bin/true" /etc/modprobe.d/usb-storage.conf `
    if [ $? != 0 ]; then
      echo -e "[31mUsb storage is enable !!![0m"
      add_check_item_error
      [ $AUTOFIX -ne 0 ] && echo "install usb-storage /bin/true" >> /etc/modprobe.d/usb-storage.conf  && echo -e "\t[32m==>fixed[0m" 
    fi
else
    echo -e "[31mUsb storage is enable !!![0m"
    add_check_item_error
    [ $AUTOFIX -ne 0 ] && echo "install usb-storage /bin/true" >> /etc/modprobe.d/usb-storage.conf  && echo -e "\t[32m==>fixed[0m" 

fi
echo "[1mChecking usb-storage disable done ![0m"
add_check_item_total
add_check_item_failed
echo ""

#Check control-alt-delete keyboard shortcuts
echo "[1mChecking CTL+ALT-DEL keyboard shortcuts ...[0m"
CHECKERROR=0
value=` grep 'exec /usr/bin/logger -p kern.warn -t init "Ctrl-Alt-Del was pressed and ignored"' /etc/init/control-alt-delete.override `
if [ $? != 0 ]; then
        echo -e "\t[31mControl-alt-delete keyboard shortcuts is enable !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && echo 'exec /usr/bin/logger -p kern.warn -t init "Ctrl-Alt-Del was pressed and ignored"' >> /etc/init/control-alt-delete.override  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking CTL+ALT-DEL keyboard shortcuts done ![0m"
add_check_item_total
add_check_item_failed
echo ""


#Check runlevel
echo "[1mChecking runlevel starting ...[0m"
CHECKERROR=0
value=`grep initdefault:  /etc/inittab |awk -F: '{ print $2}'`
if [ $value != 3 ]; then
   echo -e "\t[31mSystem runlevel is : $value[0m"
   add_check_item_error
   [ $AUTOFIX -ne 0 ] && sed -i 's/^id:.*/id:3:initdefault:/g' /etc/inittab  && echo -e "\t[32m==>fixed[0m" 
fi
echo "[1mChecking runlevel done ![0m"
add_check_item_total
add_check_item_failed
echo ""

# Check sshd configure
echo "[1mChecking sshd Port starting ...[0m"
CHECKERROR=0
value=`grep  "^Port 22" /etc/ssh/sshd_config `
if [ $? != 0 ]; then
        echo -e "\t[31mPort is not explicit config !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && sed -i 's/^[#]\{0,1\}Port.*/Port 22/g' /etc/ssh/sshd_config  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking sshd Port done ![0m "
add_check_item_total
add_check_item_failed
echo ""

echo "[1mChecking sshd Protocol starting ...[0m"
CHECKERROR=0
value=`grep  "^Protocol 2" /etc/ssh/sshd_config `
if [ $? != 0 ]; then
        echo -e "\t[31mProtocol is not config !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && sed -i 's/^[#]\{0,1\}Protocol.*/Protocol 2/' /etc/ssh/sshd_config  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking sshd Protocol done ![0m "
add_check_item_total
add_check_item_failed
echo ""

echo "[1mChecking sshd LogLevel starting ...[0m"
CHECKERROR=0
value=`grep  "^LogLevel INFO" /etc/ssh/sshd_config `
if [ $? != 0 ]; then
        echo -e "\t[31mLogLevel is not config !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && sed -i 's/^[#]\{0,1\}LogLevel.*/LogLevel INFO/' /etc/ssh/sshd_config  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking sshd LogLevel done ![0m "
add_check_item_total
add_check_item_failed
echo ""

echo "[1mChecking sshd PermitRootLogin starting ...[0m"
CHECKERROR=0
value=`grep  "^PermitRootLogin no" /etc/ssh/sshd_config `
if [ $? != 0 ]; then
        echo -e "\t[31mDisable PermitRootLogin is not config !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && sed -i 's/^[#]\{0,1\}PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking sshd RermitRootLogin done ![0m "
add_check_item_total
add_check_item_failed
echo ""

echo "[1mChecking sshd MaxAuthTries starting ...[0m"
CHECKERROR=0
value=`grep  "^MaxAuthTries 6" /etc/ssh/sshd_config `
if [ $? != 0 ]; then
        echo -e "\t[31mMaxAuthTries is not config !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && sed -i 's/^[#]\{0,1\}MaxAuthTries.*/MaxAuthTries 6/' /etc/ssh/sshd_config  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking sshd MaxAuthTries done ![0m "
add_check_item_total
add_check_item_failed
echo ""

echo "[1mChecking sshd PermitEmtyPasswords starting ...[0m"
CHECKERROR=0
value=`grep  "^PermitEmptyPasswords no" /etc/ssh/sshd_config `
if [ $? != 0 ]; then
        echo -e "\t[31mNo permitEmptyPasswords  is not config !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && sed -i 's/^[#]\{0,1\}PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking sshd PermitEmptyPasswords done ![0m "
add_check_item_total
add_check_item_failed
echo ""

echo "[1mChecking sshd Banner starting ...[0m"
CHECKERROR=0
value=`grep  "^Banner /etc/issue" /etc/ssh/sshd_config `
if [ $? != 0 ]; then
        echo -e "\t[31mBanner  is not config !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && sed -i "s/^[#]\{0,1\}Banner.*/Banner \/etc\/issue/g"  /etc/ssh/sshd_config  && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking sshd Banner done ![0m "
add_check_item_total
add_check_item_failed
echo ""


# Check Banner configuration
echo "[1mChecking banner starting ...[0m"
CHECKERROR=0
function check_banner {
value=`cat $1`
if [ "$value" != "$2" ] ;then
   echo -e "\t[31mFile : $1 with incorrect context of : $value [0m"
   add_check_item_error
   [ $AUTOFIX -ne 0 ] && echo "$2" > "$1" && echo -e "\t[32m==> fixed[0m"
fi
}
check_banner /etc/issue "ATTENTION:You have logged onto a secured server..ONLY Authorized users can access.."
check_banner /etc/issue.net "ATTENTION:You have logged onto a secured server..ONLY Authorized users can access.."
check_banner /etc/motd "ATTENTION:You have logged onto a secured server..ONLY Authorized users can access.."
echo "[1mChecking banner done ![0m "
add_check_item_total
add_check_item_failed
echo ""

# Check permission of file or diretory
echo "[1mChecking file/diretory permission starting ...[0m"
CHECKERROR=0
function file_permission_check {
value=`/bin/ls -ld "$1" 2>/dev/null` 
if [ $? -eq 0 ]; then 
#value=`echo $value |gawk '{print $1}'`
num=`stat -c %A "$1" `
if [ $num != "$2"  ]; then
    echo -e "\t[31m$1 with incorrect permission :  \t$value[0m"
    add_check_item_error
    [ $AUTOFIX -ne 0 ] && /bin/chmod $3 "$1" && echo -e "\t[32m==>fixed[0m"
fi
else
   echo -e "\tError occur when ls $1"
fi
}

file_permission_check /tmp "drwxrwxrwt" 1777
file_permission_check /var/tmp "drwxrwxrwt" 1777
file_permission_check /etc/passwd "-rw-r--r--" 644
file_permission_check /etc/group "-rw-r--r--" 644
file_permission_check /etc/shadow "----------" 000
file_permission_check /etc/gshadow "----------" 000
file_permission_check /etc/hosts "-rw-rw-r--" 664
file_permission_check /etc/inittab "-rw-------" 600
file_permission_check /etc/sysctl.conf "-rw-r--r--" 644
file_permission_check /etc/crontab  "-r--------" 400
file_permission_check /etc/securetty "-r--------" 400
file_permission_check /etc/login.defs  "-rw-r-----" 640
echo "[1mChecking file/diretory permission done ![0m"
add_check_item_total
add_check_item_failed
echo ""

#Check owner of file or diretory
echo "[1mChecking file/diretory owner starting ...[0m"
CHECKERROR=0
function file_owner_check {
value=`/bin/ls -ld "$1" 2>/dev/null`
if [ $? -eq 0 ]; then
value=`echo $value | gawk '{print $3":"$4}'`
if [ "$value" != "$2" ]; then
     echo -e "\t[31m$1 have incorrect owner : \t$value [0m"
     add_check_item_error
     [ $AUTOFIX -ne 0 ] && /bin/chown $2 $1 && echo -e "\t\t[32m==>fixed[0m"
fi
else
     echo -e "\tError occur when ls $1"
fi
}

file_owner_check /etc/passwd "root:root"
file_owner_check /etc/group "root:root"
file_owner_check /etc/shadow "root:root"
file_owner_check /etc/gshadow "root:root"
file_owner_check /etc/hosts "root:root"
file_owner_check /etc/inittab "root:root"
file_owner_check /etc/sysctl.conf "root:root"
file_owner_check /etc/crontab  "root:root"
file_owner_check /etc/securetty  "root:root"
file_owner_check /etc/login.defs  "root:root"
echo "[1mChecking file/diretory owner done ![0m"
add_check_item_total
add_check_item_failed
echo ""

#Check Dangerous files
echo "[1mChecking dangerous files starting ...[0m"
CHECKERROR=0
function dangerous_file_check {
if [ -f $1 ]; then
     echo -e "\t[31m$1 : is a dangerous file! [0m"
     add_check_item_error
     [ $AUTOFIX -ne 0 ] && /bin/rm -rf $1 && echo -e "\t\t[32m==>fixed[0m"
fi
}
dangerous_file_check /root/.rhosts 
dangerous_file_check /root/.shosts
dangerous_file_check /etc/hosts.equiv
dangerous_file_check /etc/shosts.equiv
echo "[1mChecking dangerous files done ![0m"
add_check_item_total
add_check_item_failed
echo ""

# Check kernel parameters
function check_sysctl {
value=`sysctl -n "$1"`
if [ $value -ne $2 ]; then
        echo -e "\t[31mKernel parameter : $1 with incorrect value : \t$value[0m"
        add_check_item_error
        if [ $AUTOFIX -ne 0 ]; then
                echo -e "\t\tChange kernel parameter in /proc"
                /sbin/sysctl -q -w $1=$2
                echo -e "\t\t[32m==>fixed[0m"
                echo -e "\t\tChange kernel parameter in /etc/sysctl.d/mysysctl.conf"
                grep -q "$1" /etc/sysctl.d/mysysctl.conf
                if [ $? -eq 0 ]; then
                        sed -ri "/$1/c "$1" = $2"       /etc/sysctl.d/mysysctl.conf
                else
                        echo "$1 = $2 " >> /etc/sysctl.d/mysysctl.conf
                fi
                echo -e "\t\t[32m==>fixed[0m"
               # echo "Please check with sysctl -a | grep $1 and /etc/sysctl.conf to confirm"
        fi
fi
}
echo "[1mCheck kernel parameters start ...[0m"
CHECKERROR=0
check_sysctl net.ipv4.tcp_max_syn_backlog 4096
check_sysctl net.ipv4.tcp_syncookies  1
check_sysctl net.ipv4.conf.all.rp_filter 1
check_sysctl net.ipv4.conf.all.accept_source_route 0
check_sysctl net.ipv4.conf.all.accept_redirects 0
check_sysctl net.ipv4.conf.all.secure_redirects 0
check_sysctl net.ipv4.conf.default.rp_filter 1
check_sysctl net.ipv4.conf.default.accept_source_route 0
check_sysctl net.ipv4.conf.default.accept_redirects 0
check_sysctl net.ipv4.conf.default.secure_redirects 0
check_sysctl net.ipv4.ip_forward 0
check_sysctl net.ipv4.conf.all.send_redirects 0
check_sysctl net.ipv4.conf.default.send_redirects 0
check_sysctl net.ipv4.ip_no_pmtu_disc 1
check_sysctl net.ipv4.icmp_echo_ignore_broadcasts 1
echo "[1mCheck kernel parameters done ![0m"
add_check_item_total
add_check_item_failed
echo ""


#Check /etc/pam.d/su 
echo "[1mChecking /etc/pam.d/su starting ...[0m"
CHECKERROR=0
value=`grep  "pam_wheel.so use_uid root_only" /etc/pam.d/su `
if [ $? != 0 ]; then
        echo -e "\t[31mlimitsuroot is not config !!![0m"
        add_check_item_error
        [ $AUTOFIX -ne 0 ] && sed -i 's/^[#]\{0,1\}auth\t\trequired\tpam_wheel.so use_uid.*/auth\t\trequired\tpam_wheel.so use_uid root_only/' /etc/pam.d/su  && echo "SU_WHEEL_ONLY yes" >> /etc/login.defs && echo -e "\t[32m==>fixed[0m"
fi
echo "[1mChecking /etc/pam.d/su done![0m"
add_check_item_total
add_check_item_failed
echo ""

echo "[1;32mTotal checked item : [$CHECKTOTAL], Failed item : [$CHECKFAILED] [0m"
