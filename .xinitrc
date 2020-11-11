#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

#if [ -d /etc/X11/xinit/xinitrc.d ]; then
#  for f in /etc/X11/xinit/xinitrc.d/*; do
#    [ -x "$f" ] && . "$f"
#  done
#  unset f
#fi

/usr/bin/start-pulseaudio-x11

# stop screen tearing
picom -CGb --backend xrender &

# notifications
dunst &

xset b off

sudo bash -c 'echo 0 >/sys/block/sda/queue/iosched/slice_idle'
sudo bash -c 'echo 0 >/sys/block/sda/queue/iosched/group_idle'

xsetroot -cursor_name Neutral

xrdb -merge .Xresources

envfile="$HOME/.gnupg/gpg-agent.env"
if [[ -e "$envfile" ]] && kill -0 $(grep GPG_AGENT_INFO "$envfile" | cut -d: -f 2) 2>/dev/null; then
    eval "$(cat "$envfile")"
else
    eval "$(gpg-agent --daemon --enable-ssh-support --write-env-file "$envfile")"
fi
export GPG_AGENT_INFO  # the env file does not contain the export statement
export SSH_AUTH_SOCK   # enable gpg-agent for ssh

eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa

xrandr --output DP-2 --mode 2560x1440 -r 144 --below DP-0

feh --bg-scale ~/.wallpaper.jpg

# run polybar on all monitors https://github.com/polybar/polybar/issues/515#issuecomment-291182433
for i in $(polybar -m | awk -F: '{print $1}'); do MONITOR=$i polybar -r top -c ~/.config/polybar/config & done

exec xmonad
