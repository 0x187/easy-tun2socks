#!/usr/bin/env bash
variables() {
    #colors
    yellow="\e[93m"; bold="\e[1m"; magenta="\033[1;31m"; normal="\e[0m"; cyan="\e[36m"; red="\e[91m"; GREEN="\e[32m"
    
    GATEWAY=$(/sbin/ip route | awk '/default/ { print $3 }')
    INTERFACE=$(/sbin/ip route | awk '/default/ { print $5 }')
}

check_if_running_as_root() {
    if [ "$EUID" -ne 0 ]
    then echo "Please run as root !"
    exit
    fi
}

network_interfaces () {
    read -p "$( printf "${bold}${GREEN}your machine default network interface is?$bold$magenta $INTERFACE $GREEN(y/n): $magenta" )" RESP
    if [ "$RESP" = "y" ]; then
    echo -e "${bold}${GREEN}you chose$magenta $INTERFACE "
    read_setting
    else
    echo ""
        network_list=$(ls /sys/class/net)
        in1=$(echo $network_list | awk '{print $1 }')
        in2=$(echo $network_list | awk '{print $2 }')
        in3=$(echo $network_list | awk '{print $3 }')
        in4=$(echo $network_list | awk '{print $4 }')
        in5=$(echo $network_list | awk '{print $5 }')
        in6=$(echo $network_list | awk '{print $6 }')
        echo -e "${yellow}Select your default Network interface: "
        PS3=':'
        options=("$in1" "$in2" "$in3" "$in4" "$in5" "$in6" "Quit")
        echo -ne "$GREEN"
        select opt in "${options[@]}"
        do
            case $opt in
                "$in1")
                    echo ""; echo -e "${pink}you chose$magenta $in1"
                    INTERFACE=$in1
                    read_setting
                    break
                    ;;
                "$in2")
                    echo ""; echo -e "${pink}you chose$magenta $in2"
                    INTERFACE=$in2
                    read_setting
                    break
                    ;;
                "$in3")
                    echo ""; echo -e "${pink}you chose$magenta $in3"
                    INTERFACE=$in3
                    read_setting
                    break
                    ;;
                "$in4")
                    echo ""; echo -e "${pink}you chose$magenta $in4"
                    INTERFACE=$in4
                    read_setting
                    break
                    ;; 
                "$in5")
                    echo ""; echo -e "${pink}you chose$magenta $in5"
                    INTERFACE=$in5
                    read_setting
                    break
                    ;;
                "$in6")
                    echo ""; echo -e "${pink}you chose$magenta $in6"
                    INTERFACE=$in6
                    read_setting
                    break
                    ;;            
                "Quit")
                    break
                    ;;
                *) echo "invalid option$magenta $REPLY";;
        esac
    done
    fi
}

read_setting() {
    echo ""
     read -p "$( printf "${GREEN}Please enter your remote VPN SERVER address (example$yellow 104.16.15.0): $bold$magenta")" VPN_IP
     read -p "$( printf "${GREEN}Please enter your local Proxy Port,$yellow 127.0.0.1:$bold$magenta")" PORT
     echo -e "$yellow"
     echo "Stop with CTL+C !!!"
     echo -e "$normal"
     sleep 1
}

cleanup() {
    variables
    ip link set dev tun0 down > /dev/null  2>&1
    ip r flush dev tun0  > /dev/null  2>&1
    ip r flush dev  $INTERFACE > /dev/null  2>&1
    systemctl restart NetworkManager
    sleep 1
}

tun2socks () {
	if ! ip link set dev tun0 up &>/dev/null ; then
    	 ip tuntap add mode tun dev tun0
    	 ip addr add 198.18.0.1/15 dev tun0
    	 ip link set dev tun0 up
	fi
	     ip route del default
	     ip route add $VPN_IP via $GATEWAY dev $INTERFACE metric 1
	     ip route add default via 198.18.0.1 dev tun0 metric 2
	     systemd-run --scope -p MemoryLimit=50M -p CPUQuota=10% ./tun2socks -device tun0 -proxy socks5://127.0.0.1:${PORT} --loglevel error
         cleanup
}


main() {
    variables
    printf '\e[2J\e[3J\e[H'
    check_if_running_as_root
    chmod +x ./tun2socks
    cleanup
    network_interfaces
    tun2socks
}
if [ "$1" = "-r" ]; then
    cleanup
    sleep 2
    echo "Done"
    exit 0
fi

main
