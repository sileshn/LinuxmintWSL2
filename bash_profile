# First run script for LinuxmintLmdeWSL2

blu=$(tput setaf 4)
cyn=$(tput setaf 6)
grn=$(tput setaf 2)
mgn=$(tput setaf 5)
red=$(tput setaf 1)
ylw=$(tput setaf 3)
txtrst=$(tput sgr0)

test -e /mnt/c/Users/Public/shutdown.cmd && rm /mnt/c/Users/Public/shutdown.cmd
test -e ~/shutdown.cmd && rm ~/shutdown.cmd
figlet -t -k -f /usr/share/figlet/mini.flf "Welcome to LinuxmintLmdeWSL2" | lolcat
echo -e "\033[33;7mDo not interrupt or close the terminal window till script finishes execution!!!\n\033[0m"

sed -i '/export PATH/i \\nPATH=\$PATH:/mnt/c/Windows:/mnt/c/Windows/System32:/mnt/c/Windows/System32/WindowsPowerShell/v1.0' /etc/profile

sudo systemctl daemon-reload
sudo systemctl enable wslg-init.service >/dev/null 2>&1

echo -e ${grn}"Do you want to create a new user?"${txtrst}
select yn in "Yes" "No"; do
	case $yn in
	Yes)
		echo " "
		while read -p "Please enter the username you wish to create : " username; do
			if [ "x$username" = "x" ]; then
				echo -e ${red}" Blank username entered. Try again!!!"${txtrst}
				echo -en "\033[1A\033[1A\033[2K"
				username=""
			elif grep -q "^$username" /etc/passwd; then
				echo -e ${red}"Username already exists. Try again!!!"${txtrst}
				echo -en "\033[1A\033[1A\033[2K"
				username=""
			else
				useradd -m -g users -G sudo -s /bin/bash "$username"
				echo "%sudo ALL=(ALL) ALL" >/etc/sudoers.d/sudo
				echo -en "\033[1B\033[1A\033[2K"
				passwd $username
				sed -i "/\[user\]/a default = $username" /etc/wsl.conf >/dev/null
				echo "@echo off" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
				echo "wsl.exe --terminate $WSL_DISTRO_NAME" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
				if env | grep "WT_SESSION" >/dev/null 2>&1; then
					echo "wt.exe -w 0 nt wsl.exe -d $WSL_DISTRO_NAME" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
				else
					echo "cmd /c start \"$WSL_DISTRO_NAME\" wsl.exe --cd ~ -d $WSL_DISTRO_NAME" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
				fi
				echo "del C:\Users\Public\shutdown.cmd" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
				cp ~/shutdown.cmd /mnt/c/Users/Public && rm ~/shutdown.cmd

				secs=3
				printf ${ylw}"\nTo set the new user as the default user, LinuxmintLmdeWSL will shutdown and restart!!!\n\n"${txtrst}
				while [ $secs -gt 0 ]; do
					printf "\r\033[KShutting down in %.d seconds. " $((secs--))
					sleep 1
				done

				rm ~/.bash_profile
				/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -command "Start-Process -Verb Open -FilePath 'shutdown.cmd' -WorkingDirectory 'C:\Users\Public' -WindowStyle Hidden"
				exec sleep 0
			fi
		done
		;;
	No)
		break
		;;
	esac
done

echo "@echo off" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
echo "wsl.exe --terminate $WSL_DISTRO_NAME" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
if env | grep "WT_SESSION" >/dev/null 2>&1; then
	echo "wt.exe -w 0 nt wsl.exe -d $WSL_DISTRO_NAME" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
else
	echo "cmd /c start \"$WSL_DISTRO_NAME\" wsl.exe --cd ~ -d $WSL_DISTRO_NAME" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
fi
echo "del C:\Users\Public\shutdown.cmd" | sudo tee -a ~/shutdown.cmd >/dev/null 2>&1
cp ~/shutdown.cmd /mnt/c/Users/Public && rm ~/shutdown.cmd

secs=3
printf ${ylw}"\nLinuxmintLmdeWSL2 will shutdown and restart to finish setup!!!\n\n"${txtrst}
while [ $secs -gt 0 ]; do
	printf "\r\033[KShutting down in %.d seconds. " $((secs--))
	sleep 1
done

rm ~/.bash_profile
powershell.exe -command "Start-Process -Verb Open -FilePath 'shutdown.cmd' -WorkingDirectory 'C:\Users\Public' -WindowStyle Hidden"
exec sleep 0
