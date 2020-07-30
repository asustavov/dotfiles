#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1="[\[$(tput bold)\]\u@\h\[$(tput sgr0)\] \w]\[$(tput sgr0)\]\$"  #http://bashrcgenerator.com/

