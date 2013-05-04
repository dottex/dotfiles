#
#	 initial bashrc
#                              by GO!
#

# Do nothing if not interactive shell, in fuka
[ -z "$PS1" ] && return
# Do nothing if not interactive shell, in arch seems to work, but no aqui
# [ "$BASH" = "" ] &&  return 
# source system wide aliases
if [ -f /etc/bashrc ]; then
    source /etc/bashrc
fi

export LANG="en_US.UTF-8"

if [ -f $HOME/.jona/bashrc-functions.conf ]; then
    source $HOME/.jona/bashrc-functions.conf
fi

if [ -f $HOME/.jona/bashrc-jona.conf ]; then
    source $HOME/.jona/bashrc-jona.conf
fi

if [ -f $HOME/.jona/bashrc-arch.conf ]; then
    source $HOME/.jona/bashrc-arch.conf
fi

alias homeshick="$HOME/.homesick/repos/homeshick/home/.homeshick"