#!/bin/bash
###############################################################################
##                        Update related functions                          ##
###############################################################################

# Update OS and App Store apps
appleupdate() {
	echo "🍎  Apple Software Update"
	sudo softwareupdate -i -a --verbose
	echo "🍎  Updating App Store"
	mas upgrade
}

# Update Homebrew
brewupdate() {
	echo "🍺  Updating Homebrew..."
	brew update
	echo "🍺  Upgrading Homebrew..."
	brew upgrade
	echo "🍺  Updating Homebrew Casks..."
	brew cu -a
	echo "🍺  Pruning Homebrew..."
	brew prune
	echo "🍺  Cleaning Up Homebrew..."
	brew cleanup
	echo "🍺  Checking Homebrew State..."
	brew doctor
}

# Update gems
gemupdate() {
	echo "💎  Updating Ruby System"
	gem update --system
	echo "💎  Updating Ruby Gems"
	gem update
}

# Update NPM packages
npmupdate() {
	echo "☕  Updating Global NPM Packages..."
	npm i -g npm
	for package in $(npm -g outdated --parseable --depth=0 | cut -d: -f2 | cut -d@ -f1)
	do
		echo "☕  Updating Package '$package'"
	    npm i -g $package
	done
}

# Update all software
update() {
	appleupdate
	brewupdate
	npmupdate
	gemupdate
}

###############################################################################
##                    System/Terminal related functions                      ##
###############################################################################

# Run command on wildcard matched files
# batchop '*.log' 'head -n4'
batchop() {
	# equivalent with find command:
	# find . -iname "file_pattern*" -type f -maxdepth 1 -exec command -param {} \; -exec cmd2 {} \;
	if ( [ "$1" == "" ] )
	then
		echo "Usage: batchop '[file matching pattern]' '[command]' [flag(optional)]"
		echo "Flags: -d directories only, -f files only, defaults to everything"
	else
		for flags do true; done
		for f in $1;
		do
			echo "File: $f"
			if ( [ "$flags" == '-d' ])
			then
				if ( [ -d "$f" ] )
				then
					echo ">> $2 $f"
					$2 $f;
					echo
				else
					echo "$f is a file, skipping"
					echo
				fi
			elif ( [ "$flags" == '-f' ])
			then
				if ( [ -f "$f" ] )
				then
					echo ">> $2 $f"
					$2 $f;
					echo
				else
					echo "$f is a directory, skipping"
					echo
				fi
			else
				echo ">> $2 $f"
				$2 $f;
				echo
			fi;
		done;
	fi
}

# Change directory to same path displayed in Finder window
cdf() {
	target=`osascript -e 'tell application "Finder" to if (count of Finder windows) > 0 then get POSIX path of (target of front Finder window as text)'`
	if [ "$target" != "" ]
	then
		cd "$target"
		pwd
	else
		echo 'No Finder window found' >&2
	fi
}

# Convert dmg to img
dmg2img() {
	if ( [ "$1" == "" ] || [ "$2" == "" ] )
	then
		echo "Usage: dmg2img [source] [dest]"
	else
		hdiutil convert $1 -format UDTO -o $2
	fi
}

# empty clipboard
emptyclip() {
	pbcopy < /dev/null
}

# just a quick syntax for ext4fuse to mount ext volume
extmount() {
	if ( [ "$1" == "" ] || [ "$2" == "" ] )
	then
		echo "Usage: extmount [source e.g. /dev/disk2s2] [mount point e.g. /Volumes/ext]"
	else
		sudo ext4fuse $1 $2 -o allow_other
	fi
}

# batch op for ffmpeg
ffbatch() {
	if ( [ "$1" == "" ] || [ "$2" == "" ] )
	then
		echo "Usage: ffbatch '[source pattern]' [dest path] (--noaudio)"
	else
		if ( [ "$3" == "--noaudio" ] )
		then
			AUDIO=""
		else
			AUDIO="-c:a aac -b:a 192k -strict -2"
		fi
		echo audio $AUDIO
		for f in $1
	       	do
				FILENAME=`basename $f`
				ffmpeg -i $f -c:v libx264 -preset fast -profile:v high -level 5.1 -crf 22 -pix_fmt yuv420p $AUDIO $2/${FILENAME%.*}.mp4
		done
	fi
}

# Search recursively for a filename, displaying full path in output
findfile() {
	if ( [ "$1" == "" ] )
	then
		echo "Usage: findfile [filename]"
	else
		ls -R * | awk '
		/:$/&&f{s=$0;f=0}
		/:$/&&!f{sub(/:$/,"");s=$0;f=1;next}
		NF&&f{ print s"/"$0 }' | ag $1
	fi
}

# Search for files containing supplied text string to specified folder depth
findtext() {
	if ( [ "$1" == "" ] || [ "$2" == "" ] )
	then
		echo "Usage: findtext [path] [string] [path depth (optional)]"
		echo "Path: starting path to search from."
		echo "String: string to search files for."
		echo "Path depth: Number of levels to search down from Path. 1 is specified directory only. Default is unlimited"
	else
		PATHDEPTH=""
		if ( [ "$3" != "" ] )
		then
			PATHDEPTH=" -maxdepth $3"
		fi
		find $1 -type f$PATHDEPTH -exec grep -Hi '$2' {} \;
	fi
}

# reset dns cache
flushdns() {
	sudo killall -HUP mDNSResponder
}

# go to home dir
h() {
	cd ~
}

# Kill all instances of a named process
killimg() {
	echo "Usage: killimg -s(optional) [image]"
	echo "Specifying -s uses sudo"
	if [ $1 = '-s' ]; then
		local img=[${2:0:1}]${2:1}
		sudo /bin/kill -9 $(ps ax | grep -i $img | awk '{print $1}')
	else
		local img=[${1:0:1}]${1:1}
		kill -9 $(ps ax | grep -i $img | awk '{print $1}')
	fi
}

# gzip with a nice progress bar
pgzip() {
	if ( [ "$1" == "" ] )
	then
		echo "Usage: pgzip [file] [keep original (0 | 1)]"
	else
		if ( [ "$2" != "0" ] && [ "$2" != "1" ] )
		then
			echo "Usage: pgzip [file] [keep original (0 | 1)]"
			read -p "Delete $1 on successful creation of $1.gz? [Y/n] " -n 1 -r
			echo
			if [[ $REPLY =~ ^[Nn]$ ]]
			then
			    REMOVE="0"
			else
				REMOVE="1"
			fi
		else
			[ "$2" = "1" ] ; REMOVE=$?
		fi
		pv "$1" | gzip > "$1.gz"
		if ( [ $REMOVE == "1" ] && [ -e "$1.gz" ] )
		then
			rm "$1"
		fi
	fi
}

# display some useful and pretty info
welcome() {
    local upSeconds="$(sysctl -n kern.boottime | cut -c14-18)"
    local secs=$((upSeconds%60))
    local mins=$((upSeconds/60%60))
    local hours=$((upSeconds/3600%24))
    local days=$((upSeconds/86400))
    local UPTIME=$(printf "%d days, %02dh%02dm%02ds" "$days" "$hours" "$mins" "$secs")
	
	local istats=$(istats)
	istats=${istats::${#istats}-64}
    local df_out=()
    local line
    while read line; do
        df_out+=("$line")
    done < <(df -h /)

    local rst="$(tput sgr0)"
    local fgblk="${rst}$(tput setaf 0)" # Black - Regular
    local fgred="${rst}$(tput setaf 1)" # Red
    local fggrn="${rst}$(tput setaf 2)" # Green
    local fgylw="${rst}$(tput setaf 3)" # Yellow
    local fgblu="${rst}$(tput setaf 4)" # Blue
    local fgpur="${rst}$(tput setaf 5)" # Purple
    local fgcyn="${rst}$(tput setaf 6)" # Cyan
    local fgwht="${rst}$(tput setaf 7)" # White

    local bld="$(tput bold)"
    local bfgblk="${bld}$(tput setaf 0)"
    local bfgred="${bld}$(tput setaf 1)"
    local bfggrn="${bld}$(tput setaf 2)"
    local bfgylw="${bld}$(tput setaf 3)"
    local bfgblu="${bld}$(tput setaf 4)"
    local bfgpur="${bld}$(tput setaf 5)"
    local bfgcyn="${bld}$(tput setaf 6)"
    local bfgwht="${bld}$(tput setaf 7)"
	
    local out
	
	out+="${fggrn}$(date +"%A, %e %B %Y, %r")\n\n"
	out+="${fgylw}${df_out[0]}\n"
	out+="${fgylw}${df_out[1]}\n\n${fgwht}"
	out+=${istats}
	out+="\n\n${fgred}Uptime.............: ${UPTIME}\n"
	out+="${fgred}Running Processes..: $(ps ax | wc -l | tr -d " ")\n"
	out+="${fgred}IP Address.........: $(ifconfig | grep "inet " | grep -v 127.0.0.1 | cut -d\  -f2)\n\n"
	
    echo -e "\n$out"
}

###############################################################################
##                       Software Specific functions                         ##
###############################################################################

# Patch broken CORE keygens
fixcore() {
	upx -d CORE\ Keygen.app/Contents/MacOS/CORE\ Keygen
}

# Fix CUDA persistent update required notification
fixcuda() {
	if ( [ "$1" == "" ] )
	then
		echo "Usage: fixcuda [version]"
		echo "where [version] is what's specified as latest in CUDA prefs window"
	else
		NEWVER=$(ls /Library/Frameworks/CUDA.framework/Libraries/libcuda_355.* | tail -1)
		sudo cp -a $NEWVER /Library/Frameworks/CUDA.framework/Libraries/libcuda_$1_mercury.dylib
	fi
}

# reset synergy when it's acting up
syn() {
	echo Killing all Synergy processes
	killall synergy-tray
	killall synergy-config
	killall synergy-service
	killall synergy-core
}

# launch vivaldi in dev mode, copy custom css to new install dir
vivdev() {
	cd "$(find /Applications/Vivaldi.app/Contents/Versions -maxdepth 6 -type d -name "vivaldi" | head -1)"
	if ( [ "$1" == "run" ] )
	then
		open /Applications/Vivaldi.app --args --debug-packed-apps --silent-debugger-extension-api
	elif ( [ "$1" == "cust" ] )
	then
		cp ~/Dropbox/Apps/Vivaldi/custom.css ./style/
		mate browser.html
	fi
}

###############################################################################
##                          SSL related functions                            ##
###############################################################################

genssl() {
	if ( [ "$1" == "" ] || [ "$2" == "" ] )
	then
		echo "Usage: genssl [name] [domain]"
	else
		CONFIG_FILE=$1.conf
		echo Building config file $CONFIG_FILE...
		echo [req] > $CONFIG_FILE
		echo default_bits = 1024 >> $CONFIG_FILE
		echo distinguished_name = req_distinguished_name >> $CONFIG_FILE
		echo req_extensions = v3_req >> $CONFIG_FILE
		echo [req_distinguished_name] >> $CONFIG_FILE
		echo [v3_req] >> $CONFIG_FILE
		echo basicConstraints = CA:FALSE >> $CONFIG_FILE
		echo keyUsage = nonRepudiation, digitalSignature, keyEncipherment >> $CONFIG_FILE
		echo subjectAltName = @alt_names >> $CONFIG_FILE
		echo [alt_names] >> $CONFIG_FILE
		echo DNS.1 = $2 >> $CONFIG_FILE
		echo Generating SSL keys...
		sudo openssl genrsa -out /usr/local/etc/httpd/ssl/$1.key 2048
		sudo openssl req -new -x509 -key /usr/local/etc/httpd/ssl/$1.key -out /usr/local/etc/httpd/ssl/$1.crt -days 3650 -subj /CN=$2
		sudo openssl rsa -in /usr/local/etc/httpd/ssl/$1.key -out /usr/local/etc/httpd/ssl/$1.key.rsa
		sudo openssl req -new -key /usr/local/etc/httpd/ssl/$1.key -subj "/C=CA/ST=NS/L=Halifax/O=8pi/CN=$2/emailAddress=kris@8pi.ca/" -out /usr/local/etc/httpd/ssl/$1.csr
		sudo openssl req -new -key /usr/local/etc/httpd/ssl/$1.key.rsa -subj "/C=CA/ST=NS/L=Halifax/O=8pi/CN=$2/" -out /usr/local/etc/httpd/ssl/$1.csr -config /usr/local/etc/httpd/ssl/$1.conf
		sudo openssl x509 -req -days 365 -in /usr/local/etc/httpd/ssl/$1.csr -signkey /usr/local/etc/httpd/ssl/$1.key -out /usr/local/etc/httpd/ssl/$1.crt
		sudo openssl x509 -req -extensions v3_req -days 365 -in /usr/local/etc/httpd/ssl/$1.csr -signkey /usr/local/etc/httpd/ssl/$1.key.rsa -out /usr/local/etc/httpd/ssl/$1.crt -extfile /usr/local/etc/httpd/ssl/$1.conf
		sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /usr/local/etc/httpd/ssl/$1.crt
		echo Keys $1 for $2 successfully generated...
		rm $CONFIG_FILE
		openssl req -text -noout -in $1.csr
		echo Add to your VirtualHost entry:
		echo SSLEngine on
		echo SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL
		echo SSLCertificateFile /usr/local/etc/httpd/ssl/$1.crt
		echo SSLCertificateKeyFile /usr/local/etc/httpd/ssl/$1.key
	fi	
}

# Generate PEM file from SSH Public Key file
pemfile() {
	if ( [ "$1" = "" ] || [ "$2" = "" ] || [ "$3" = "" ] )
	then
		echo "Usage: pemfile [file] [user] [host]"
	else
		CWD=$(pwd)
		cd ~/.ssh
		ssh-keygen -t rsa -b 2048 -v
		ssh-copy-id -i $1.pub $2@$3
		openssl rsa -in $1 -outform pem > $1.pem
		chmod 400 $1.pem
		rm $1
		rm $1.pub
		cd $CWD
	fi
}

###############################################################################
##                     Web dev/server related functions                      ##
###############################################################################

# launch bash terminal on a docker image
dcbash() {
	if ( [ "$1" = "" ] )
	then
		echo "Usage: dcbash [container]"
	else
		docker exec -it $1 /bin/bash
	fi
}

# put up docker compose, make sure everything is running
dcu() {
	# check for docker file, make sure not excluded
	if [ -e "docker-compose.yml" ] || [ -e "docker-compose.yaml" ]; then
		# is docker.app running?
		PROC=`ps aux | sed -n /[Dd]ocker.app/p`
		if [ "${PROC:-null}" = null ]; then
			# no, load it up
			LOADING=true
			printf "Loading Docker daemon"
		    open /Applications/Docker.app
			# wait until it's finished loading before proceeding
			while [ $LOADING == true ]
			do
				# is docker ps returning an error (can't find docker daemon)
				DOCKER_PROC=`docker ps 2>/dev/null`
				if [ "${DOCKER_PROC:-null}" = null ]; then
					LOADING=true
				else
					LOADING=false
				fi
				# print a dot for appearance of progresss then sleep 1s
				printf "."
				sleep 1
			done
			echo Docker daemon loaded successfully
		fi
		# launch docker-compose up
		docker-compose up
	else
		echo "docker-compose.yml does not exist"
	fi
}

# Delete a git branch locally and remotely
delbranch() {
	if ( [ "$1" == "" ] )
	then
		echo "Usage: delbranch [branchname]"
	else
		git branch -d $1
		git push origin --delete $1
	fi
}

# launch full stack of gulp/webpack/docker
devstack() {
	# set arg options to local to this function
	local OPTIND
	# default exclude values to false
	EXCLUDE_GULP=false
	EXCLUDE_WEBPACK=false
	EXCLUDE_DOCKER=false
	# loop through args
	while getopts ":hx:" arg; do
	  case $arg in
	    x) case ${OPTARG} in
				gulp)
					# arg -x gulp, mark for exclusion
					EXCLUDE_GULP=true
					;;
				webpack)
					# arg -x webpack, mark for exclusion
					EXCLUDE_WEBPACK=true
					;;
				docker)
					# arg -x docker, mark for exclusion
					EXCLUDE_DOCKER=true
					;;
			esac
	      ;;
	    h | help)
			# -h or -help arg passed
			echo "Usage: devstack [-x docker|gulp|webpack]"
			echo "    Specify a -x parameter for each tool you wish to exclude, eg to exclude gulp and webpack:"
			echo "        devstack -x gulp -x webpack"
			# and quit
			return
			;;
	  esac
	done
	# make sure we're not skipping everything
	if [ $EXCLUDE_GULP == false ] || [ $EXCLUDE_WEBPACK == false ] || [ $EXCLUDE_DOCKER == false ]; then
		# start under assumption nothing has been done
		DO_SOMETHING=false
		# check for docker file, make sure not excluded
		if [ -e "docker-compose.yml" ] && [ $EXCLUDE_DOCKER == false ]; then
			# is docker.app running?
			PROC=`ps aux | sed -n /[Dd]ocker.app/p`
			if [ "${PROC:-null}" = null ]; then
				# no, load it up
				LOADING=true
				printf "Loading Docker daemon"
			    open /Applications/Docker.app
				# wait until it's finished loading before proceeding
				while [ $LOADING == true ]
				do
					# is docker ps returning an error (can't find docker daemon)
					DOCKER_PROC=`docker ps 2>/dev/null`
					if [ "${DOCKER_PROC:-null}" = null ]; then
						LOADING=true
					else
						LOADING=false
					fi
					# print a dot for appearance of progresss then sleep 1s
					printf "."
					sleep 1
				done
				echo Docker daemon loaded successfully
			fi
			# launch docker-compose up in a new tab
			ttab -G eval "docker-compose up"
			DO_SOMETHING=true
		fi
		# check for gulp file, make sure not excluded
		if ( [ -e "gulpfile.js" ] || [ -e "gulpfile.babel.js" ] ) && [ $EXCLUDE_GULP == false ]; then
			# launch gulp watch in a new tab
			ttab -G eval "gulp watch"
			DO_SOMETHING=true
		fi
		# check for webpack file, make sure not excluded
		if [ -e "webpack.config.js" ] && [ $EXCLUDE_WEBPACK == false ]; then
			# launch webpack --watch in a new tab
			ttab -G eval "webpack --watch"
			DO_SOMETHING=true
		fi
		# nothing happened, show a message letting user know
		if [ $DO_SOMETHING == false ]; then
			echo "No files found for Docker, Gulp, or Webpack. Make sure to run this command from the right directory"
		fi
	fi
}

# Start/stop web services
web() {
	if ( [ "$1" == "start" ] )
	then
		brew services start php72
		brew services start mariadb
		brew services start redis
		sudo brew services start dnsmasq
		sudo brew services start httpd24
	elif ( [ "$1" == "stop" ] )
	then
		brew services stop php72
		brew services stop mariadb
		brew services stop redis
		sudo brew services stop dnsmasq
		sudo brew services stop httpd24
	elif ( [ "$1" == "restart" ] )
	then
		brew services restart php72
		brew services restart mariadb
		brew services restart redis
		sudo brew services restart dnsmasq
		sudo brew services restart httpd24
	else
		echo "Usage: web [stop|start|restart]"
	fi
}

###############################################################################
##                     Finder/Desktop related functions                      ##
###############################################################################

# Set displaytime on notification banners, or set back to default
bannertime() {
	delayTime=$1
	if  [[ $delayTime == [0-9]* ]] || [ $delayTime == 'default' ]
	then
		if [ $delayTime == 'default' ]
		then
			defaults delete com.apple.notificationcenterui bannerTime
		else
			defaults write com.apple.notificationcenterui bannerTime $delayTime
		fi
	else
		echo 'Usage: bannertime [time]'
		echo 'Time can be in seconds, or default'
	fi
}

# Fix TotalFinder in Mojave
fixtf() {
	sudo tccutil reset AppleEvents
	osascript -e "tell application \"Finder\" to «event BATFinit»"
}

# Toggle view hidden files in Finder/Desktop
hidden() {
	state=$(defaults read com.apple.finder AppleShowAllFiles)
	if [ $state == "YES" ]; then state="NO"; else state="YES"; fi
	defaults write com.apple.finder AppleShowAllFiles $state
	killall Finder
}

# Fix stalled "Open With" menu
openwreset() {
	/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -kill -seed -r -f -v -domain local -domain user -domain system
}

###############################################################################
##                       Wordpress related functions                         ##
###############################################################################

# Back up Wordpress SQL database, infer credentials from supplied wp-config
wpbackup() {
	if ( [ "$1" == "" ] || [ "$2" = "" ] )
	then
		echo "Usage: sqlbackup [wp-config file] [backup filename]"
	else
		if ( [ -e $1 ] )
		then
			WPDBNAME=`cat $1 | grep DB_NAME | cut -d \' -f 4`
			WPDBUSER=`cat $1 | grep DB_USER | cut -d \' -f 4`
			WPDBPASS=`cat $1 | grep DB_PASSWORD | cut -d \' -f 4`
			if ( [ "$WPDBNAME" == "" ] || [ "$WPDBUSER" == "" ] )
			then
				echo "Unable to load database settings from $1. Please check the file and try again"
			else
				mysqldump --user=$WPDBUSER --password=$WPDBPASS $WPDBNAME > "$2"
				gzip "$2"
			fi
		else
			echo "Wordpress config $1 file not found"
		fi
	fi
}

# Restore Wordpress SQL database, infer credentials from supplied wp-config
wprestore() {
	if ( [ "$1" == "" ] || [ "$2" = "" ] )
	then
		echo "Usage: sqlrestore [wp-config file] [backup filename]"
	else
		if ( [ -e $1 ] )
		then
			if ( [ -e $2 ] )
			then
				WPDBNAME=`cat $1 | grep DB_NAME | cut -d \' -f 4`
				WPDBUSER=`cat $1 | grep DB_USER | cut -d \' -f 4`
				WPDBPASS=`cat $1 | grep DB_PASSWORD | cut -d \' -f 4`
				if ( [ "$WPDBNAME" == "" ] || [ "$WPDBUSER" == "" ] )
				then
					echo "Unable to load database settings from $1. Please check the file and try again"
				else
					mysql -u $WPDBUSER -p$WPDBPASS $WPDBNAME < "$2"
				fi
			else
				echo "SQL file $2 not found"
			fi
		else
			echo "Wordpress config $1 file not found"
		fi
	fi
}

# Appropriately Set file and dir permissions for Wordpress on this and all child directories
wpperms() {
	if [ "$1" = "" ]
	then
		CWD=$(pwd)/.
	else
		CWD=`cd "$1"; pwd`/.
	fi
	read -p "Do you want to set standard Wordpress permissions on $CWD?" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		echo "Setting directory permissions on $CWD"
		sudo find $CWD -type d -exec chmod 0775 {} +
		echo "Setting file permissions on $CWD"
		sudo find $CWD -type f -exec chmod 0664 {} +
	fi
}

###############################################################################
##                         MySQL related functions                           ##
###############################################################################

# Backup specified MySQL Database
sqlbackup() {
	if ( [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] || [ "$4" == "" ] )
	then
		echo "Usage: sqlbackup [user] [password] [database] [destination file]"
	else
		$(which mysqldump) --user=$1 --password=$2 $3 > "$4"
		gzip "$4"
	fi
}

# Backup all databases
sqlbackupall() {
	if ( [ "$1" == "" ] )
	then
		echo "Usage: sqlbackupall [backup path]"
	else
		echo "Please enter MySQL root password:"
		read -s ROOT_PASSWORD
		BACKUP_DIR="$1/$(date +"%F")"
		mkdir -p "$BACKUP_DIR"
		databases=`$(which mysql) --user=root -p$ROOT_PASSWORD -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`
		for db in $databases; do
			$(which mysqldump) --force --opt --user=root -p$ROOT_PASSWORD --databases $db | gzip > "$BACKUP_DIR/$db.gz"
		done
	fi
}

# Restore specified MySQL Database
sqlrestore() {
	if ( [ "$1" = "" ] || [ "$2" = "" ] || [ "$3" = "" ] || [ "$4" = "" ] )
	then
		echo "Usage: sqlrestore [user] [password] [database] [source file]"
	else
		$(which mysql) -u $1 -p$2 $3 < "$4"
	fi
}

###############################################################################
##                         iTerm2 related functions                          ##
###############################################################################

# display git branch of current dir in iterm badge
function iterm2_print_user_vars() {
	GIT_BRANCH="$( (git branch 2> /dev/null) | grep \* | cut -c3-)"
	if ( [ "$GIT_BRANCH" != "" ] )
	then
		GIT_SHOW="[$GIT_BRANCH]"
	else
		GIT_SHOW=""
	fi
	iterm2_set_user_var gitBranch "$GIT_SHOW"
}
