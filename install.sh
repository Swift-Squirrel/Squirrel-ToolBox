#!/bin/bash
#
#  install.sh
#  SquirrelToolbox
#
#  Created by Filip Klembara 10/7/2017
#
#

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "help" ]; then
	echo "Usage: ./install.sh [options]"
	echo ""
	echo "Installation script fot SquirrelToolbox"
	echo ""
	echo "options:"
	echo "  --verbose, -v           Increase verbosity of informational output"
	echo "  --verbose-all, -va      Set verbose flag in subprocesses"
	echo "  --help, -h              Prints this help"
	exit 0
elif [ "$1" == "-v" ] || [ "$1" == "--verbose" ]; then
	VERBOSE=1
elif [ "$1" == "-va" ] || [ "$1" == "--verbose-all" ]; then
	VERBOSE=1
	VERBOSE_ALL=1
fi

COFF='\033[0m'		# Text Reset
B='\033[0;34m'		# Blue

green() {
	local G='\033[0;32m'
	echo -e "$G$1$COFF"
}

red() {
	local R='\033[0;31m'
	echo -e "$R$1$COFF"	
}

error() {
	red "ERR\nERROR: $1"
    exit 1
}

ok() {
	green "$1"
}

verbose() {
	local C='\033[0;36m'
	if [ "$VERBOSE" == "1" ]; then
		echo -e "$C$1$COFF"
	fi
}

warning() {
	local Y='\033[0;33m'
	echo -e "$Y$1$COFF"
}

logVOK() {
	if [ "$VERBOSE" == "1" ]; then
		ok "$1"
	else
		ok "OK"
	fi
}

spinner() {
    local pid=$!
    local delay=0.5
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "[%c]" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b"
    done
    printf "   \b\b\b"
	wait $pid
	return "$?"
}

########################################
# Check if squirrel exists on system
########################################

EXECUTABLE="squirrel"
usrBinPath="/usr/local/bin"
resultBinPath="$usrBinPath/$EXECUTABLE"
verbose "Checking for existence $resultBinPath"
if [ -e "$resultBinPath" ]; then
	while true; do
	    read -p "`warning "$resultBinPath already exists. Do you want to overwrite it? [Yn] "`" yn
	    case $yn in
	        [Yy]* ) break;;
	        [Nn]* ) exit;;
	        * ) echo "Please answer Y or n.";;
	    esac
	done
else
	verbose "Checking for existance of $EXECUTABLE (should not)"
	hash "$EXECUTABLE" 2>/dev/null
	if [ "$?" == "0" ]; then
		error "executable $EXECUTABLE already exists at `whereis "$EXECUTABLE"`"
	fi
	verbose "$EXECUTABLE does not exists"
fi

########################################
# Check system environment
########################################

echo "Checking environment"

echo -ne "\tswift4\t\t\t"
verbose "\n\tchecking existence of swift"
hash swift 2>/dev/null
if [[ "$?" -ne 0 ]]; then
    error 'Missing dependency '\''swift'\'' please install swift 4'
fi
verbose "\tchecking version of swift (should be 4.0.0+)"
if [ "`swift --version | head -n 1 | cut -d' ' -f4 | cut -d'.' -f1`" != "4" ] && [ "`swift --version | head -n 1 | cut -d' ' -f3 | cut -d'.' -f1`" != "4" ]; then
	error 'Wrong swift version, install swift 4' 
fi

logVOK "\tswift4 OK"
verbose 'Enviroment check successful'

########################################
# Build from code
########################################

echo -e "\nBuilding toolbox"

echo -en "Resolving build dependencies\t"

verbose "\nswift package resolve"
if [ "$VERBOSE" == "1" ]; then
	if [ "$VERBOSE_ALL" == "1" ]; then
		swift package -v resolve
	else
		swift package resolve
	fi
else
	swift package resolve 1>/dev/null 2>/dev/null &
	spinner
fi

if [ "$?" != 0 ]; then
	error 'Can not resolve dependencies'
fi
logVOK "Resolving successful"
echo -ne "Building source\t\t\t"
verbose "\nswift build -c release"
if [ "$VERBOSE" == "1" ]; then
	if [ "$VERBOSE_ALL" == "1" ]; then
		swift build -v -c release
	else
		swift build -c release
	fi
else
	swift build -c release 1>/dev/null  2>/dev/null &
	spinner
fi
if [ "$?" != 0 ]; then
	error 'Build failed'
fi
logVOK "Building successful"

verbose "Building from source successful"

########################################
# Move to /usr/local/bin
########################################

echo -ne "Moving SquirrelToolbox\t\t"

verbose "\nChecking permissions for $usrBinPath"
if [ ! -w "$usrBinPath" ]; then
	error "Dont have permissions to write to $usrBinPath, use \`sudo\`"
fi
verbose "Permissions ok"
verbose "Getting binary path"

binPath="`swift build -c release --show-bin-path`/SquirrelToolbox"

if [ "$?" != "0" ] || [ ! -x "$binPath" ]; then
	error "Could not get binary ($binPath) or you don't have permissions to execute it"
fi
verbose "Bin path is $binPath"
verbose "mv \"$binPath\" \"$resultBinPath\""
mv "$binPath" "$resultBinPath"
if [ "$?" != 0 ]; then
	error "mv \"$binPath\" \"$resultBinPath\" returns with error"
fi

logVOK "Moving successful"

########################################
# Check executable
########################################

echo -ne "Checking \`$EXECUTABLE help\`\t"
verbose "\nChecking return status"
helpRes="`"$EXECUTABLE" help`"
statusRes="$?"
if [ "$statusRes" != "0" ]; then
	if [ "$statusRes" == "127" ]; then
		error "Install error - $EXECUTABLE does not exists"
	else
		error "Install error"
	fi
fi
verbose "Status is ok"
verbose "Checking stdout"
if [ helpRes == "" ]; then
	error "Help should not be empty"
fi
verbose "Stdout is ok"
logVOK "Executable OK"

########################################
# Everything is ok!
########################################
ok "\nInstallation was successful, run \`squirrel help\` to show help"
