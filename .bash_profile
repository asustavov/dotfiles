#!/usr/bin/bash

#export GDK_BACKEND=wayland
export MOZ_ENABLE_WAYLAND=1

export PATH="$HOME/bin:$PATH"


[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ "$(tty)" = "/dev/tty1" ]; then
	sway
fi
