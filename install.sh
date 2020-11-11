#!/bin/bash

# manual work: 
# create partitions
# get arch-chroot working
# create efi partition
# install bootloader etc

# 

# install all packages
pacman -S --noconfirm --needed - < packages

git clone https://aur.archlinux.org/yay-git.git

pushd yay-git
makepkg -si
popd

rm -rf yay-git

yay -S --noconfirm --needed - < packages-aur

mkdir -p ~/.config/kitty
ln -s ./kitty.conf ~/.config/kitty/kitty.conf

mkdir -p ~/.config/dunst
ln -s ./dunst/dunstrc ~/.config/dunst/dunstrc

# install xmonad
mkdir -p ~/.xmonad
ln -s ./xmonad.hs ~/.xmonad/xmonad.hs

cabal install --lib xmonad xmonad-contrib xmonad-utils utf8-string X11
cabal build xmonad.hs

xmonad --recompile

mkdir -p ~/.config/polybar
ln -s ./polybar/config ~/.config/polybar/config

rm ~/.zshrc.local
ln -s .zshrc.local ~/.zshrc.local

ln -s .wallpaper.jpg ~/.wallpaper.jpg

ln -s .Xresources ~/.Xresources

ln -s .themes ~/.themes

ln -s .gtkrc-2.0 ~/.gtkrc-2.0

mkdir -p .config/gtk-3.0
ln -s .gtk3settings.ini ~/.config/gtk-3.0/settings.ini