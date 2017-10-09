#!/bin/bash
#
#  install.sh
#  SquirrelToolbox
#
#  Created by Filip Klembara 10/7/2017
#
#

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
	if [ "$VERBOSE" == "0" ]; then
		red "ERR"
	fi
	red "ERROR: $1"
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
# Check arguments
########################################


HELP="0"
VERBOSE="0"
VERBOSE_ALL="0"
FORCE="0"

for i in "$@" ; do
    if [ "$i" == "-h" ] || [ "$i" == "--help" ] || [ "$i" == "help" ]; then
        HELP="1"
        break
    elif [ "$i" == "-v" ] || [ "$i" == "--verbose" ]; then
    	VERBOSE="1"
    elif [ "$i" == "-va" ] || [ "$i" == "--verbose-all" ]; then
    	VERBOSE_ALL="1"
    	VERBOSE="1"
    elif [ "$i" == "-f" ] || [ "$i" == "--force" ]; then
    	FORCE="1"
    else
    	red "Unknown argument $i"
    	exit 1
    fi
done

if [ "$expectArg" == "1" ]; then
	red "Missing argument for $waitingForArg"
	exit 1
fi


if [[ $HELP == 1 ]]; then
	echo "Usage: ./install.sh [options]"
	echo ""
	echo "Installation script fot SquirrelToolbox"
	echo ""
	echo "options:"
	echo "  --force, -f             Force install"
	echo "  --verbose, -v           Increase verbosity of informational output"
	echo "  --verbose-all, -va      Set verbose flag in subprocesses"
	echo "  --help, -h              Prints this help"
	exit 0
fi

EXECUTABLE="squirrel"
usrBinPath="/usr/local/bin"
resultBinPath="$usrBinPath/$EXECUTABLE"

########################################
# Check if squirrel exists on system
########################################

echo -en "Checking system preconditions\t"
if [ "$FORCE" == "0" ]; then
	verbose "\nChecking for existence $resultBinPath"
	if [ -e "$resultBinPath" ]; then
		while true; do
		    read -p "`warning "\n$resultBinPath already exists. Do you want to overwrite it? [Yn] "`" yn
		    case $yn in
		        [Yy]* ) verbose "User allow overwrite $resultBinPath"; break;;
		        [Nn]* ) verbose "User cancel installation"; exit;;
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
else
	verbose "\nSkipping existence checking of $EXECUTABLE due to --force flag"
fi
verbose "\nChecking permissions for $usrBinPath"
if [ ! -w "$usrBinPath" ]; then
	error "Dont have permissions to write to $usrBinPath"
fi
verbose "Permissions ok"

logVOK "System preconditions ok"

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
	error 'Could not resolve dependencies'
fi
logVOK "Resolving successful"

echo -ne "Building from source\t\t"
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
verbose "Building successful"

binPath="`pwd`/.build/release/SquirrelToolbox"

verbose "Checking for existence of $binPath (should exists)"
if [ ! -e "$binPath" ]; then
	error "Could not find SquirrelToolbox executable at $binPath"
fi
verbose "$binPath exists"

verbose "Checking if $binPath is executable and you have permissions"
if [ ! -x "$binPath" ]; then
	error "You don't have permissions to execute $binPath"
fi
verbose "Permissions to execute ok"

logVOK "Building successful"

########################################
# Move to /usr/local/bin
########################################

echo -ne "Moving SquirrelToolbox\t\t"

verbose "\nmv \"$binPath\" \"$resultBinPath\""
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
verbose "$EXECUTABLE help"
helpRes="`"$EXECUTABLE" help`"
statusRes="$?"
if [ "$statusRes" != "0" ]; then
	if [ "$statusRes" == "127" ]; then
		error "Install error - $EXECUTABLE does not exists"
	else
		error "$EXECUTABLE returns nonzero status"
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
# Cleaning
########################################
CLEAN_ERROR="0"
echo -en "Clean artifacts\t\t\t"
verbose "\nswift package clean"
swift package clean
if [ "$?" != "0" ]; then
	verbose "`warning "Warning: swift package clean error"`"
	CLEAN_ERROR="1"
fi
verbose "rm -rf .build"
rm -rf .build
if [ "$?" != "0" ]; then
	verbose "`warning "Warning: rm -rf .build error"`"
	CLEAN_ERROR="1"
fi
verbose "rm Package.resolved"
rm Package.resolved
if [ "$?" != "0" ]; then
	verbose "`warning "Warning: rm Package.resolved error"`"
	CLEAN_ERROR="1"
fi

if [ "$CLEAN_ERROR" == "1" ]; then
	if [ "$VERBOSE" == "1" ]; then
		warning "Clean warnings generated"
	else
		warning "WARNINGS"
	fi
else
	logVOK "Clean successful"
fi
if [ "$CLEAN_ERROR" != "0" ]; then
	warning "Could not clean all artifacts"
fi
########################################
# Installation done
########################################
ok "\nInstallation was successful, run \`squirrel help\` to show help"
