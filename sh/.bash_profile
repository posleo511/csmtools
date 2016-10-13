# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs
export PIG_HOME=/opt/pig/pig-0.16.0
export SPARK_HOME=/usr/local/spark
export R_HOME=/usr/lib64/R
export ORACLE_HOME=/usr/lib/oracle/11.2/client64
export OCI_LIB=/research/msdap/oracle-client-install/instant-client/instantclient_11_2
export TNS_ADMIN=/home/msdap
export LD_LIBRARY_PATH=/research/msdap/oracle-client-install/instant-client/instantclient_11_2:/usr/local/lib:/usr/lib/oracle/11.2/client64/lib:$LD_LIBRARY_PATH

PATH=$PATH:$HOME/bin
PATH=${PATH}:${PIG_HOME}/bin
PATH=${PATH}:${SPARK_HOME}/bin

export PATH

source ~/.aliases

# sudo functions
function installr {
  ids=( $@ )
  id="${ids[@]}";
  pr=$( echo "c('${id// /','}')")
  sudo su - -c "R -q -e \"install.packages(${pr}, repos='http://cran.rstudio.com/')\""
}

function installs {
  pr=$( readlink -f $1 )
  sudo su - -c "R -q -e \"install.packages('${pr}', repos = NULL, type='source')\""
}

#-- An awesome collection of useful things from the ol' interweb ---------------
# Most things pirated mercilessly from:
# https://github.com/cep21/jackbash/blob/master/bashrc

# Supporting Definitions ####
source "$HOME/.bash/term_colors"
# get from https://raw.github.com/git/git/master/contrib/completion/git-prompt.sh
source $HOME/.bash/git-prompt.sh

# Variables ####
export LS_COLOR='--color=tty'
export EDITOR=$( which vi )
PROMPT_COLOR=$G
if [ ${UID} -eq 0 ]; then
  PROMPT_COLOR=$R ### root is a red color prompt
fi
# Setting PS1
# (1) The time shows when each command was executed, when I get back to my terminal
# (2) Git information really important for git users
# (3) Prompt color is red if I'm root
# (4) The last part of the prompt can copy/paste directly into an SCP command
# (5) Color highlight out the current directory because it's important
# (6) The export PS1 is simple to understand!
# (7) If the prev command error codes, the prompt '>' turns red
CURSOR_PROMPT="$ "
export PS1="$Y\t$N $W"'$(__git_ps1 "(%s) ")'"$N$PROMPT_COLOR\u@\H$N:$C\w$N\n"'$CURSOR_PROMPT '

# Aliases ####
alias ll='ls -lah $LS_COLORS'
alias skim="(head -5; tail -5) <"
alias bh="cat ~/.bash_history | grep"

# Functions ####
# go up n directories
function cdn(){ for i in `seq $1`; do cd ..; done;}

# 'cd' and 'll'
function cl(){ cd "$@" && ll; }

# asker function, returns 1 for "falsy" answers
function ask()
{
    echo -n "$@" '[y/n] ' ; read -r ans
    case "$ans" in
        y*|Y*) return 0 ;;
        *) return 1 ;;
    esac
}

# extractor function by file extension
function ex() {
     if [ -f "$1" ] ; then
         case "$1" in
             *.tar.bz2)   tar xvjf "$1"        ;;
             *.tar.gz)    tar xvzf "$1"     ;;
             *.bz2)       bunzip2 "$1"       ;;
             *.rar)       unrar x "$1"     ;;
             *.gz)        gunzip "$1"     ;;
             *.tar)       tar xvf "$1"        ;;
             *.tbz2)      tar xvjf "$1"      ;;
             *.tgz)       tar xvzf "$1"       ;;
             *.jar)       jar xf "$1"       ;;
             *.zip)       unzip "$1"     ;;
             *.Z)         uncompress "$1"  ;;
             *.7z)        7z x "$1"    ;;
             *)           echo "'$1' cannot be extracted via >extract<" ;;
         esac
     else
         echo "'$1' is not a valid file"
     fi
}

# edit a file no matter where it is
function anyvi()
{
    if [ -e "$1" ] || [ -f "$1" ]; then
        $EDITOR "$1"
    else
        $EDITOR "$(which "$1")"
    fi
}
complete -cf anyvi


