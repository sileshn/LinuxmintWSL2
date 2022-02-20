# First run script for LinuxmintWSL

blu=$(tput setaf 4)
grn=$(tput setaf 2)
red=$(tput setaf 1)
ylw=$(tput setaf 3)
txtrst=$(tput sgr0)

figlet -t -k -f /usr/share/figlet/mini.flf "Welcome to LinuxmintWSL"
echo -e "\033[33;7mDo not interrupt or close the terminal window till script finishes execution!!!\n\033[0m"

diskvol=$(mount | grep -m1 ext4 | cut -f 1 -d " ")
sudo resize2fs $diskvol
disksize=$(df -k | grep $diskvol | cut -f8 -d " ")

if [ $disksize -le 263174212 ]; then
    echo -e ${ylw}"Your virtual hard disk has a maximum size of 256GB. If your distribution grows more than 256GB, you will see disk space errors. This can be fixed by expanding the virtual hard disk size and making WSL aware of the increase in file system size. For more information, visit this site (\033[34mhttps://docs.microsoft.com/en-us/windows/wsl/vhd-size\033[33m).\n"${txtrst} | fold -sw 120
    echo -e ${grn}"Would you like to resize your virtual hard disk?"${txtrst}
    select yn in "Yup" "Nope"; do
        case $yn in
            Yup)
                echo " "
                secs=5
                while [ $secs -gt 0 ]; do
                    printf ${ylw}"\r\033[KUse diskpart to resize your VHD and restart LinuxmintWSL. System will shut down in %.d seconds. "${txtrst} $((secs--))
                    sleep 1
                done
                wsl.exe --shutdown $WSL_DISTRO_NAME
                ;;
            Nope)
                break
                ;;
        esac
    done
fi

echo -e ${grn}"\nDo you want to create a new user?"${txtrst}
select yn in "Yup" "Nope"; do
    case $yn in
        Yup)
            echo " "
            while read -p "Please enter the username you wish to create : " username; do
                if [ x$username = "x" ]; then
                    echo -e ${red}" Blank username entered. Try again!!!"${txtrst}
                    echo -en "\033[1A\033[1A\033[2K"
                    username=""
                elif grep -q "$username" /etc/passwd; then
                    echo -e ${red}"Username already exists. Try again!!!"${txtrst}
                    echo -en "\033[1A\033[1A\033[2K"
                    username=""
                else
                    useradd -m -g users -G sudo -s /bin/bash "$username"
                    echo "%sudo ALL=(ALL) ALL" >/etc/sudoers.d/sudo
                    echo -en "\033[1B\033[1A\033[2K"
                    passwd $username
                    sed -i "/\[user\]/a default = $username" /etc/wsl.conf >/dev/null
                    echo " "
                    secs=5
                    while [ $secs -gt 0 ]; do
                        printf ${ylw}"\r\033[KSystem needs to be restarted. Shutting down in %.d seconds."${txtrst} $((secs--))
                        sleep 1
                    done
                    rm ~/.bash_profile
                    wsl.exe --terminate $WSL_DISTRO_NAME
                fi
            done
            ;;
        Nope)
            clear
            rm ~/.bash_profile
            break
            ;;
    esac
done
