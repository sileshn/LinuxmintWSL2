#!/bin/bash
# First run script for LinuxmintWSL.

blu=$(tput setaf 4)
cyn=$(tput setaf 6)
grn=$(tput setaf 2)
mgn=$(tput setaf 5)
red=$(tput setaf 1)
ylw=$(tput setaf 3)
txtrst=$(tput sgr0)

diskvol=$(mount | grep -m1 ext4 | cut -f 1 -d " ")
sudo resize2fs $diskvol >/dev/null 2>&1
disksize=$(df -k | grep $diskvol | cut -f8 -d " ")
osname=$(/mnt/c/Windows/System32/wbem/wmic.exe os get Caption | sed -n 2p)
width=$(echo $COLUMNS)

if [ $width -gt 120 ]; then
    width=120
fi

if [ ! -e ~/.hushlogin ] && env | grep "WT_SESSION" >/dev/null 2>&1; then
    echo -e "\033[33;7mPlease read this important message!!!\n\033[0m"
    echo -e ${mgn}"You are running LinuxmintWSL in Windows Terminal on $osname\n"${txtrst}
    echo -e "LinuxmintWSL has been test run only in Windows command prompt on Windows 10. Windows Terminal displays an error message \033[31m[process exited with code 1 (0x00000001)]\033[0m whenever WSL is shutdown or terminated from within. This error is displayed during the disk resize and user creation steps. Though this doesn't affect the working of LinuxmintWSL in any way, some of you may feel otherwise and report errors. I suggest you complete the initial setup in a Windows command prompt and switch to windows terminal post setup. If you choose to use Windows Terminal, ignore the displayed error message.\n" | fold -sw $width
    read -n 1 -p "Press any key to continue..."
    touch ~/.hushlogin
    clear
fi

test -f /mnt/c/Users/Public/vhdresize.txt && rm /mnt/c/Users/Public/vhdresize.txt
test -f ~/vhdresize.txt && rm ~/vhdresize.txt
figlet -t -k -f /usr/share/figlet/mini.flf "Welcome to LinuxmintWSL" | lolcat
echo -e "\033[33;7mDo not interrupt or close the terminal window till script finishes execution!!!\n\033[0m"

if [ $disksize -le 263174212 ]; then
    echo -e ${ylw}"Your virtual hard disk has a maximum size of 256GB. If your distribution grows more than 256GB, you will see disk space errors. This can be fixed by expanding the virtual hard disk size and making WSL aware of the increase in file system size. For more information, visit this site (\033[36mhttps://docs.microsoft.com/en-us/windows/wsl/vhd-size\033[36m).\n"${txtrst} | fold -sw $width
    echo -e ${grn}"Would you like to resize your virtual hard disk?"${txtrst}
    select yn in "Yup" "Nope"; do
        case $yn in
            Yup)
                echo " "
                test -f ~/vhdresize.txt || touch ~/vhdresize.txt
                while read -p ${mgn}"Path to virtual disk (e.g. C:\Users\silesh\wsl\ext4.vhdx) : "${txtrst} -r vhdpath; do
                    if [ x$vhdpath = "x" ]; then
                        echo -e ${red}"Path cannot be blank."${txtrst}
                        echo -en "\033[1A\033[1A\033[2K"
                        vhdpath=""
                    else
                        wsl_path=$(wslpath -a $vhdpath)
                        if [ ! -f $wsl_path ]; then
                            echo -e ${red}"Disk does not exist.  "${txtrst}
                            echo -en "\033[1A\033[1A\033[2K"
                            vhdpath=""
                        else
                            echo "select vdisk file=\"$vhdpath\"" | sudo tee -a ~/vhdresize.txt >/dev/null 2>&1
                            break
                        fi
                    fi
                done
                while read -p ${mgn}"Size of virtual disk in MegaBytes(e.g. 512000 for 512GB) : "${txtrst} vhdsize; do
                    if [[ $vhdsize =~ ^-?[0-9]+$ ]]; then
                        if [ $vhdsize -le 256000 ]; then
                            echo -e ${red}"Disk size should be greater than 256000 MegaBytes."${txtrst}
                            echo -en "\033[1A\033[1A\033[2K"
                            vhdsize=0
                        else
                            echo -en "\033[1B\033[1A\033[2K"
                            echo "expand vdisk maximum=$vhdsize" | sudo tee -a ~/vhdresize.txt >/dev/null 2>&1
                            echo " "
                            printf "%s" "$(<~/vhdresize.txt)"
                            echo " "
                            echo -e ${grn}"\nPlease review your input displayed above. Is is ok to proceed?"${txtrst}
                            select yn in "Proceed" "Edit"; do
                                case $yn in
                                    Proceed)
                                        break
                                        ;;
                                    Edit)
                                        "${EDITOR:-nano}" ~/vhdresize.txt
                                        break
                                        ;;
                                esac
                            done
                            cp ~/vhdresize.txt /mnt/c/Users/Public
                            break
                        fi
                    else
                        echo -e ${red}"Disk size cannot be blank and has to be numeric.  "${txtrst}
                        echo -en "\033[1A\033[1A\033[2K"
                    fi
                done

                echo " "
                printf ${ylw}"Please grant powershell, elevated permissions to run diskpart when requested!!!\n"${txtrst}
                if env | grep "WT_SESSION" >/dev/null 2>&1; then
                    printf ${ylw}"\r\033[KIgnore error message and close window manually after diskpart launches. "${txtrst}
                    sleep 2
                else
                    printf ${ylw}"\r\033[KThis window will close after diskpart launches. "${txtrst}
                    sleep 2
                fi
                powershell.exe -command "Start-Process -Verb RunAs 'diskpart.exe' -ArgumentList '/s C:\Users\Public\vhdresize.txt' -WindowStyle Hidden"
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
                    if env | grep "WT_SESSION" >/dev/null 2>&1; then
                        printf ${ylw}"\r\033[KIgnore error message and close window manually."${txtrst}
                        sleep 2
                    else
                        printf ${ylw}"\r\033[KSystem will shutdown to set default user."${txtrst}
                        sleep 2
                    fi
                    rm ~/.bash_profile
                    rm ~/.hushlogin
                    wsl.exe --terminate $WSL_DISTRO_NAME
                fi
            done
            ;;
        Nope)
            clear
            rm ~/.bash_profile
            rm ~/.hushlogin
            break
            ;;
    esac
done
