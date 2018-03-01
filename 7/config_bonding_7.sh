#!/bin/bash

echo -e "-------------------------------------------------------------------------------"
echo -e "hostname is:\t$(hostname)"
echo "IP address:"
for INTERF in $(cat /proc/net/dev | awk -F: '(NR>2){print $1}'| sort |grep -v lo )
do
        echo -e "\t$INTERF\t\c"
#       echo "$(ifconfig $INTERF | awk -F: '/inet addr/{print $2}'| awk '{print $1}')"
        echo "$(ifconfig $INTERF |awk '/inet /{print $2}')"
done
echo -e "-------------------------------------------------------------------------------"

NWIFILEPATH=/etc/sysconfig/network-scripts
GNWFILEPATH=/etc/sysconfig/network


#Configure hostname
configure_hostname()
{ 
        clear
        echo -e "\n"
        echo -e "_______________________________________________________________________________\n"
        echo -e "Configure hostname"
        echo -e "_______________________________________________________________________________"
        echo -e "\n\n"

        echo -e "Please input hostname:\t\c" 
        read HOSTNAME
        hostname $HOSTNAME

        cp -a $GNWFILEPATH $GNWFILEPATH.bak$(date +%y%m%d%H%M)
        hostnamectl set-hostname $HOSTNAME
        echo -e "\nSuccessful configuration "
        echo -e "hostname is:\t$(hostname)"
        echo -e "\n\nPress any key to continue..."
        read tt
} 

#network configure
configure_netinterface()
{
        echo -e "All network adapters："
        echo -e "[\c"
        for INTERF in $(cat /proc/net/dev | awk -F: '(NR>2){print $1}'| sort |grep -v lo )
        do
                echo -e "$INTERF  \c"   
        done
        echo "]"
        echo "" 

        echo "Please select a network adapters:" 
        echo -e "\c"
        read INTERFACE

        if grep $INTERFACE /proc/net/dev > /dev/null 2>&1
        then
                echo -e "  Please input ipaddress/network or gateway"
                echo -e "  IP\t\t\tNETMASK\t\t\tGATEWAY"
                read -p "  " IPADDR NETMASK GATEWAY

                mkdir $NWIFILEPATH/backup > /dev/null 2>&1
                mv $NWIFILEPATH/ifcfg-$INTERFACE $NWIFILEPATH/backup/ifcfg-$INTERFACE.bak$(date +%y%m%d%H%M) > /dev/null 2>&1

                echo -e "DEVICE=\"$INTERFACE\""   > $NWIFILEPATH/ifcfg-$INTERFACE
                echo -e "BOOTPROTO=\"none\""      >> $NWIFILEPATH/ifcfg-$INTERFACE
                echo -e "HWADDR=\"$(cat /sys/class/net/$INTERFACE/address)\"" >> $NWIFILEPATH/ifcfg-$INTERFACE
                echo -e "NM_CONTROLLED=\"no\""    >> $NWIFILEPATH/ifcfg-$INTERFACE
                echo -e "ONBOOT=\"yes\""          >> $NWIFILEPATH/ifcfg-$INTERFACE
                echo -e "TYPE=\"Ethernet\""       >> $NWIFILEPATH/ifcfg-$INTERFACE
                echo -e "IPADDR=$IPADDR"          >> $NWIFILEPATH/ifcfg-$INTERFACE
                echo -e "NETMASK=$NETMASK"        >> $NWIFILEPATH/ifcfg-$INTERFACE
                echo -e "GATEWAY=$GATEWAY"        >> $NWIFILEPATH/ifcfg-$INTERFACE

                echo -e "\nConigure finishing!"
        else
                echo -e "\nInput error!!!"
        fi

}


#bonding configure
configure_bonding()
{
        echo -e "All network adapters:"
        echo -e "[\c"
        for INTERF in $(cat /proc/net/dev | awk -F: '(NR>2){print $1}'| sort |grep -v lo )
        do
                echo -e "$INTERF  \c"   
        done
        echo "]"
        echo "" 

        echo "Please bondname and network device name:"
        echo -e "bondname\tnetwork1\tnetwork2" 
        echo -e "\c"
        read BONDNAME INTERFACE1 INTERFACE2


        if ! test -z $INTERFACE1  && grep $INTERFACE1 /proc/net/dev > /dev/null 2>&1
        then
                if ! test -z $INTERFACE2 && grep $INTERFACE2 /proc/net/dev > /dev/null 2>&1
                then
                        echo -e "  Please input ipaddress/network or gateway"
                        echo -e "  IP\t\t\tNETMASK\t\t\tGATEWAY"
                        read -p "  " IPADDR NETMASK GATEWAY
                  if [ -n "$IPADDR" ] && [ -n "$NETMASK" ]; then
                      set_rhel7_bond_config -b $BONDNAME -m 1 -i $IPADDR -n $NETMASK -g $GATEWAY -t static -s "miimon=100 primary=ens32"
                      set_rhel7_ethx_config $BONDNAME $INTERFACE1
                      set_rhel7_ethx_config $BONDNAME $INTERFACE2
                      echo -e "\nConigure finishing!"
                    else
                      echo -e "\nInput IP or netmask is error!!!"
                  fi
                else
                        echo -e "\nNetwork2 input error!!!"
                fi

        else
                echo -e "\nNetwork1 input error!!!！"
                ! test -z $INTERFACE2 && grep $INTERFACE2 /proc/net/dev/ > /dev/null 2>&1 || echo -e "Network input error!!!" 
        fi
}

set_rhel7_bond_config ()
{
unset OPTIND
while getopts 'b:m:i:n:g:s:t:' opt; do
    case $opt in
        b) bond_name=$OPTARG;;
        m) bond_mode=$OPTARG;;
        i) ip=$OPTARG;;
        n) mask=$OPTARG;;
        g) gateway=$OPTARG;;
        s) bond_opts=$OPTARG;;
        t) network_type=$OPTARG;;
    esac
done
bond_config_file="/etc/sysconfig/network-scripts/ifcfg-$bond_name"
echo $bond_config_file
if [ -f $bond_config_file ]; then
    echo "Backup original $bond_config_file to bondhelper.$bond_name"
    mv $bond_config_file /etc/sysconfig/network-scripts/bondhelper.$bond_name -f
fi

if [ "static" == $network_type ]; then 
    ip_setting="IPADDR=$ip
NETMASK=$mask
GATEWAY=$gateway
USERCTL=no"
else
    ip_setting="USERCTL=no"
fi
cat << EOF > $bond_config_file
DEVICE=$bond_name
ONBOOT=yes
BOOTPROTO=$network_type
$ip_setting
BONDING_OPTS="mode=$bond_mode $bond_opts"
NM_CONTROLLED=no
EOF
}

set_rhel7_ethx_config()  {
    bond_name=$1
    eth_name=$2

    eth_config_file="/etc/sysconfig/network-scripts/ifcfg-$eth_name"
    if [ -f $eth_config_file ]; then
        echo "Backup original $eth_config_file to bondhelper.$eth_name"
        mv $eth_config_file /etc/sysconfig/network-scripts/bondhelper.$eth_name -f
    fi

    cat << EOF  > $eth_config_file
DEVICE=$eth_name
BOOTPROTO=none
ONBOOT=yes
MASTER=$bond_name
SLAVE=yes
USERCTL=no
NM_CONTROLLED=no
EOF
}



configure_clear()
{
        echo -e "Clear network configure..."
	mkdir $NWIFILEPATH/backup > /dev/null 2>&1
        for INTERF in $(cat /proc/net/dev | awk -F: '(NR>2){print $1}'| sort |grep -v lo )
        do
                mv $NWIFILEPATH/ifcfg-*$INTERF* $NWIFILEPATH/backup/ifcfg-$INTERF.bak$(date +%y%m%d%H%M) > /dev/null 2>&1
        done
	    modprobe -r bonding > /dev/null 2>&1
        systemctl restart network > /dev/null 2>&1
        for INTERF in $(cat /proc/net/dev | awk -F: '(NR>2){print $1}'| sort |grep -v lo |grep -v bond)
        do
                mods=`ethtool -i $INTERF |grep driver | awk '{ print $2}'`
                modprobe -r $mods && modprobe $mods
        done
        echo -e "\nConigure finishing!"
        echo
}



testing_network()
{
        echo -e "Testing network status..."
        ipaddr=`ip route |grep default |awk '{ print $3 }'`
        if [ -n "$ipaddr" ]; then
             ping $ipaddr -c 1
             if [ $? == 0 ]; then
                 echo -e "\nNetwork status is ok!!!"
             else
                 echo -e "[31mNetwork status is failed, please checking network!!!![0m"
             fi
        else
             echo -e "[31mPlease configure gateway!!![0m"
        fi
        echo 
}

configure_network()
{
        while [ 1=1 ]
        do
                clear
                echo -e "\n"
                echo -e "\t\t1. Single network configure"
                echo -e "\t\t2. Bonding network configure"
                echo -e "\t\t3. Restart network service"
		echo -e "\t\t4. clear network configure"
                echo -e "\t\t5. Testing network status"
                echo -e "\t\t6. Return"
                echo -e "\n"
                echo -e "-------------------------------------------------------------------------------"
                read -p "Please choice: " BONDORNOT
                case $BONDORNOT in
                        "1")
                                echo -e "\n\n"
				configure_netinterface
                                echo -e "\n\nPress any key to continue..."
                                read tt
                        ;;

                        "2")
                                echo -e "\n\n"
                                configure_bonding
                                echo -e "\n\nPress any key to continue..."
                                read tt
                        ;;

                        "3")
                                echo -e "\n\n"
                   		systemctl restart network  
                                echo -e "\nNetwork service restart finishing! "
                                echo -e "\n\nPress any key to continue..."
                                read tt
                        ;;


                       "4")
                                echo -e "\n\n"
				configure_clear
                                echo -e "\n\nPress any key to continue..."
                                read tt
                        ;;


                       "5")
                                echo -e "\n\n"
                                testing_network
                                echo -e "\n\nPress any key to continue..."
                                read tt
                        ;;


                        "6")
                                break
                        ;;

                        *)
                                echo -e "Please input the correct option（1-6）"
                                sleep 2
                        ;;
                esac
        done
}



#Configure menu
                        while [ 1=1 ]
                        do
                                echo -e "\n"
				echo -e "-------------------------------------------------------------------------------"
                                echo -e "\n"
                                echo -e "\t\t1. configure hostname"
                                echo -e "\t\t2. configure network"
                                echo -e "\t\t3. exit"
                                echo -e "\n"
				echo -e "-------------------------------------------------------------------------------"


                                read -p "Please choice: " CONCHOICE
                                case $CONCHOICE in
                                        "1")
                                                configure_hostname
                                        ;;

                                        "2")
                                                configure_network
                                        ;;

                                        "3")
                                                exit 0
                                        ;;

                                        *)
                                                echo -e "Please input the correct option（1-3）"
                                                sleep 2
                                        ;;
                                esac

                        done

