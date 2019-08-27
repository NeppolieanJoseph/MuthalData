#!/bin/ksh

## This program is for setting up ssh on a target systems.
## It updates webdeps authorized_keys file with our public key
## and modifies the sudoers file.

# Static values
publicKey="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA38lSKriqq5KmvGBatNeBW8Cmwa8+bOYIx759eeyAEhHU+mbZUQJB4OlQuUMZW5s8CoP1u7KsQcAp9/fu9Rq2XZ2EFAHmZ02pezZO+GjUzw6hBECKtKhw+n9vqkjuKL6Z7/CKEKgKJz2fJsZWLqYJSMHE/ae45U3nlNQ1kRW1Npr2d+Hz2k8V42JXCTfSXet2C4fTZ/Zg7sg1FKbx2NFHOrE7aC/nTMI9OMwccIwxklVPQ1OM7ruFC3j9UT63TBCxJGY3PUyge8HN7AOULIOeQVwoTx5S9rHQ62VYZlQ9E5a75bJcRQJZgVCNFWIkrNGB9CwHLw0MVHuSrTtRhJ2NBw=="
webdepCmd="webdep ALL=(root) NOPASSWD: /usr/bin/perl"
publicKeyStr="rsa-key-20120507"

# ~~~~~~~~~ Functions ~~~~~~~~~~~

function PrintIt {
   msg=$1
   if [[ -f $logFile ]]; then
      echo "$msg" >> $logFile
   else
      print "$msg"
   fi
}

function PrintItNoNL {
   msg=$1
   if [[ -f $logFile ]]; then
      echo "$msg" >> $logFile
   else
      echo -n "$msg"
   fi
}

function Fail {
   cmd=$1
   PrintIt "ERROR: $cmd"
   exit 1
}

function Warn {
   cmd=$1
   PrintIt "WARNING: $cmd"
}

function Pass {
   cmd=$1
   PrintIt "SUCCESS: $cmd"
   exit 0
}

# ~~~~~~~~~ Main ~~~~~~~~~~~

if [[ -f $1 ]]; then
   logFile=$1
fi

webdepHome=$(echo ~webdep)
authKeys="$webdepHome/.ssh/authorized_keys"
sudoersFile="/etc/sudoers"
linuxId="n"
redHatId="r"
solarisId="s"
aixId="a"
GREP=grep
host=$(hostname)

PrintIt "Webdep's home directory is: $webdepHome";

if [[ $webdepHome == "/" || $webdepHome == "/etc" || $webdepHome == "/dev" || $webdepHome == "/var" || $webdepHome == "/sys" ]]; then
   Fail "The webdep home directory is invalid: $webdepHome";
fi

#hostType=${host:0:1}
hostType="a"

if [[ $hostType == $solarisId ]]; then
   sudoersFile="/usr/local/etc/sudoers"
   GREP="/usr/xpg4/bin/grep"
fi

if [[ $hostType == $redHatId ]]; then
   hostType=$linuxId
fi

if [[ -f $logFile ]]; then
   echo "Running via DSM" >> $logFile
fi

if [[ ! -f $sudoersFile ]]; then
   Fail "Unable to detect sudoers file at ${sudoersFile}\n"
fi

if [[ ! -f $authKeys ]]; then
   Warn "Unable to detect authorized keys file at ${authKeys}\n"
fi

PrintIt "Configuring SSH files...\n"

cmd="cd $webdepHome"
$($cmd) || Fail "$cmd"

PrintIt "Detecting $webdepHome/.ssh directory..\n"

if [[ ! -d "$webdepHome/.ssh" ]]; then
   PrintIt "Creating $webdepHome/.ssh directory...\n"
   
   cmd="mkdir -pm 700 $webdepHome/.ssh"
   $($cmd) || Fail "$cmd"
else
   PrintIt "Changing $webdepHome/.ssh directories mode to 700...\n"

   cmd="chmod 700 $webdepHome/.ssh"
   $($cmd) || Fail "$cmd"
fi

PrintIt "Adding the public key to the authorized keys file...\n"

if [[ -f $authKeys ]]; then
   PrintIt "Backing up ${authKeys}...\n"
   cmd="cp $authKeys ${authKeys}.escm" 
   $($cmd) || Fail "$cmd"
else
   PrintIt "Touching ${authKeys}...\n"
   cmd="touch $authKeys" 
   $($cmd) || Fail "$cmd"
   cmd="chmod 644 $authKeys" 
   $($cmd) || Fail "$cmd"
fi

$GREP -iq $publicKeyStr $authKeys
if [[ $? != 0 ]]; then 
   cmd="echo $publicKey"
   $($cmd >> $authKeys) || Fail "$cmd"
else
   PrintIt "   The public key already exists in the authorized keys file. Not modifying...\n"
fi

PrintItNoNL "Making the webdep UID non-expiring "

# The non-expiring commands below cannot be executed from a subshell
if [[ $hostType == $solarisId ]]; then
   PrintIt "for the $host Solaris system...\n"
   passwd -x -1 webdep 2>&1
elif [[ $hostType == $linuxId ]]; then
   PrintIt "for the $host Linux system...\n"
   chage -I -1 -m 0 -M 99999 -E -1 webdep 2>&1
elif [[ $hostType == $aixId ]]; then
   PrintIt "   Not setting AIX webdep account to non-expiring\n"
   #cp /etc/security/user /etc/security/user.acm
else
   Warn "Unsupported system name detected: ${host}. Can't set webdep's account to non-expiring!\n"
fi

PrintIt "Modifying the sudoers file...\n"

$GREP -iq "$webdepCmd" $sudoersFile
if [[ $? != 0 ]]; then 
   cmd="cp $sudoersFile ${sudoersFile}.escm" 
   $($cmd) || Fail "$cmd"
   cmd="echo $webdepCmd"
   $($cmd >> $sudoersFile) || Fail "$cmd"
else
   PrintIt "   The sudoers file already has our line for webdep.\n"
fi

if [[ -d ${webdepHome} ]]; then
	PrintIt "Changing owner:group to webdep:web for $webdepHome...\n"
	cmd="chown webdep:web ${webdepHome}"
	$($cmd) || Fail "$cmd"
	
	PrintIt "Changing $webdepHome permissions to 755...\n"
	cmd="chmod 755 ${webdepHome}"
	$($cmd) || Fail "$cmd"
else
	PrintIt "$webdepHome doesn't exist. Not changing its attributes.\n"
fi

if [[ -d ${webdepHome}/acm ]]; then
	PrintIt "Changing owner:group to webdep:web for $webdepHome/acm...\n"
	cmd="chown -R webdep:web ${webdepHome}/acm"
	$($cmd) || Fail "$cmd"
	
	PrintIt "Changing $webdepHome/acm permissions to 755...\n"
	cmd="chmod 755 ${webdepHome}/acm"
	$($cmd) || Fail "$cmd"
else
	PrintIt "$webdepHome/acm doesn't exist. Not changing its attributes.\n"
fi

PrintIt "Changing owner:group to webdep:web for $webdepHome/.ssh...\n"

cmd="chown -R webdep:web ${webdepHome}/.ssh"
$($cmd) || Fail "$cmd"


Pass "Successfully configured SSH on target: $host"
