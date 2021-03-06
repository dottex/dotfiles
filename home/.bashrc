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


if [ -f $HOME/.comun/bashrc-functions.conf ]; then
    source $HOME/.comun/bashrc-functions.conf
fi

if [ -f $HOME/.comun/bashrc-comun.conf ]; then
    source $HOME/.comun/bashrc-comun.conf
fi

if [ -f $HOME/.comun/bashrc-arch.conf ]; then
    source $HOME/.comun/bashrc-arch.conf
fi

##
alias homeshick="$HOME/.homesick/repos/homeshick/home/.homeshick"
