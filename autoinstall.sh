#!/bin/bash

# This script is meant for easy install Tuxbot using curl/wget
printf "Welcome to Tuxbot's installation guide.\n"
printf "\nLog file is in ~/.tuxinstall.log\n"
# Command checking 
if (( $EUID != 0 )); then
  printf "\n\nError : Please run this script as ROOT"
  exit 0
fi

if ! [ -x "$(command -v git)" ]; then
  printf "\n\nError : Git is not installed"
  exit 0
fi

if ! [ -x "$(command -v pip3.7)" ]; then
  printf "\n\nError : pip3.7 is not installed (using pip3.7 command)\nPlease install it to continue"
  exit 0
fi

# Tuxbot directory answer 
read -p "In which directory Tuxbot should be installed ? : [/srv/]" na
na=${na:-"/srv/"}

# Cloning tuxbot USING GNOUS'S GIT MIRROR
printf "Cloning git repository, please wait... \n" &
git clone https://git.gnous.eu/gnouseu/tuxbot-bot $na/tuxbot-bot &> ~/.tuxinstall.log
sleep 1 

printf "Tuxbot has been cloned to $na.\n" 5 50 
sleep 1 
printf "Installing pip modules, please wait...\n" 5 50 &
sleep 1 

# Downloading PIP modules using pip3.7 cmd
pip3.7 install -U discord.py[voice] &> ~/.tuxinstall.log
cd $na/tuxbot-bot 
pip3.7 install -r requirements.txt &> ~/.tuxinstall.log
sleep 1 

printf "Tuxbot's python dependencies have been downloaded\n"
sleep 1 

# Answers to generate config
function generateConfig {
    DATE=`date +%Y-%m-%d`
    read -p "Enter your Discord API Token : " cToken
    read -p "Enter the bot client ID : " cID
    read -p "Enter the log channel ID : " cLogID
    read -p "Enter the main channel of your server : " cSrvID
    read -p "What game tuxbot should display as playing (eg : 'Eat potatoes') : " cGame
    read -p "What is you're discord user ID (for admin cmd) : " cAdmin
    echo "------------"
    read -p "MySQL's tuxbot user : " mSQLuser
    read -p "MySQL's tuxbot password : " mSQLpass
    read -p "MySQL's tuxbot database name : " mSQLdb
    echo """
#Generated by Tuxbot install script 
#$DATE
token = \"$cToken\"
client_id = \"$cID\" 
log_channel_id = \"$cLogID\" 
main_server_id = \"$cSrvID\" 
game = \"$cGame\"
authorized_id = [\"$cAdmin\"] 
prefix = [\".\"]
description = '.'
mysql = { 
    \"host\": \"localhost\",
    \"username\": \"$mSQLuser\",
    \"password\": \"$mSQLpass\",
    \"dbname\": \"$mSQLdb\"
}
fonts = {
    \"normal\": \"NotoSansCJK-Regular.ttc\",
    \"bold\": \"NotoSansCJK-Bold.ttc\"
}
""" &> $na/tuxbot-bot/config.py
}

printf "Do you want to generate config file ?\n1 - Yes (selected)\n2 - No\n" 
read -p "(1-2) : " initConf
initConf=${initConf:-"1"}
case $initConf in
   1) generateConfig;;
esac

#Non login user
echo "Adding tuxbot non-login user..."
useradd -M tuxbot
sleep 1 

#Chown all perms to the non login user
echo "Fixing permissions..."
chown tuxbot:tuxbot -R $na/tuxbot-bot/
sleep 1 

#Create the service file 
echo "Adding Tuxbot service & start it..."
echo """[Unit]
Description=Tuxbot, a discord bot
#After=network.target

[Service]
Type=simple
User=tuxbot

Restart=on-failure
Restart=always
RestartSec=1

WorkingDirectory=$na/tuxbot-bot/
ExecStart=/usr/bin/env python3.7 $na/tuxbot-bot/bot.py

StandardOutput=file:/var/log/tuxbot.log

[Install]
WantedBy=multi-user.target
""" &> /lib/systemd/system/tuxbot.service
systemctl daemon-reload
systemctl start tuxbot
sleep 1 
echo "Activation of tuxbot at startup..."
sleep 1 
systemctl enable tuxbot 

#End message
echo """


Tuxbot should be correctly installed.
Please check if all is good by execute : 
systemctl status tuxbot
And .ping command in discord.

Configuration file is $na/tuxbot-bot/config.py
Main tuxbot directory is $na/tuxbot-bot/

Any question ? => Make an issue on github

https://git.gnous.eu/gnouseu/tuxbot-bot
https://github.com/outout14/tuxbot-legacy

"""
