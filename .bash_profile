# Load custom aliases
source ~/.bash_aliases

# Set prompt
#export PS1="\u@\h:\W \[\033[0;31m\]>\[\033[0;33m\]>\[\033[0;34m\]>\[\033[0m\] "
# Smiley prompt 😀 🙁
export PS1="\`if [ \$? = 0 ]; then echo '\u@\h:\W \[\033[0;31m\]>\[\033[0;33m\]>\[\033[0;34m\]>\[\033[0m\] '; else echo '\u@\h:\W🙁 \[\033[0;31m\]>\[\033[0;33m\]>\[\033[0;34m\]>\[\033[0m\] '; fi\`"

# Setup and load Node Version Manager
# export NVM_DIR="/Users/crowley/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Add node to path
export PATH="/usr/local/opt/node/bin:$PATH"

# Add sbin to path
export PATH="/usr/local/sbin:$PATH"

# Add Android SDK to path
export PATH="/usr/local/Cellar/android-sdk/24.4.1_1/bin:$PATH"

# Add PHP to path
export PATH="$(brew --prefix php72)/bin:$PATH"

# Add SQLite to path
export PATH="/usr/local/opt/sqlite/bin:$PATH"

# Set Androind SDK Home
export ANDROID_HOME=/usr/local/Cellar/android-sdk/24.4.1_1

# Init Ruby Environment Manager
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

# Set up TheFuck functionality
eval "$(thefuck --alias)"

# Bash History Settings
export HISTSIZE=10000
export HISTFILESIZE=10000

# Load custom functions
source ~/.bash_functions
export PATH="/usr/local/opt/e2fsprogs/bin:$PATH"
export PATH="/usr/local/opt/e2fsprogs/sbin:$PATH"

if ( [ $(ps a | awk '{print $2}' | grep -vi "tty*" | uniq | wc -l) -le 1 ] )
then
	welcome
fi
