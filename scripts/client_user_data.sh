#!/bin/bash

sudo apt update
sudo apt install -y xfce4 xrdp links
sudo dpkg-reconfigure lightdm
sudo echo xfce4-session >~/.xsession
sudo systemctl enable xrdp
sudo service xrdp restart
sudo wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt -y install ./google-chrome-stable_current_amd64.deb
