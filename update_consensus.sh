#!/bin/bash

# Author: coincashew.eth | coincashew.com
# License: GNU GPL
# Source: https://github.com/coincashew/ethpillar
# Description: EthPillar is a one-liner setup tool and node management TUI
#
# Made for home and solo stakers 🏠🥩

BASE_DIR=$HOME/git/ethpillar

# Load functions
source $BASE_DIR/functions.sh

# Auto-update Endurance network config if outdated
auto_update_endurance_config

# Get machine info
_platform=$(get_platform)
_arch=$(get_arch)

function promptYesNo(){
    if whiptail --title "Update ${CLIENT}" --yesno "Installed Version is: $VERSION\nLatest Version is:    $TAG\n\nReminder: Always read the release notes for breaking changes: $CHANGES_URL\n\nDo you want to update $CLIENT to $TAG?" 15 78; then
  		updateClient
  		promptViewLogs
	fi
}

function promptViewLogs(){
    if whiptail --title "Update complete" --yesno "Would you like to view logs and confirm everything is running properly?" 8 78; then
		if [[ ${NODE_MODE} =~ "Validator Client Only" ]]; then
			sudo bash -c 'journalctl -fu validator | ccze -A'
		else
			sudo bash -c 'journalctl -fu consensus | ccze -A'
		fi
    fi
}

function getLatestVersion(){
	case "$CLIENT" in
	  Lighthouse)
	    TAG_URL="https://api.github.com/repos/sigp/lighthouse/releases/latest"
	    CHANGES_URL="https://github.com/sigp/lighthouse/releases"
	    ;;
	  Lodestar)
	    TAG_URL="https://api.github.com/repos/ChainSafe/lodestar/releases/latest"
	    CHANGES_URL="https://github.com/ChainSafe/lodestar/releases"
	    ;;
	  Teku)
	    TAG_URL="https://api.github.com/repos/ConsenSys/teku/releases/latest"
	    CHANGES_URL="https://github.com/ConsenSys/teku/releases"
	    ;;
	  Nimbus)
		TAG_URL="https://api.github.com/repos/status-im/nimbus-eth2/releases/latest"
		CHANGES_URL="https://github.com/status-im/nimbus-eth2/releases"
		;;
	  Prysm)
	    TAG_URL="https://api.github.com/repos/prysmaticlabs/prysm/releases/latest"
	    CHANGES_URL="https://github.com/prysmaticlabs/prysm/releases"
	    ;;
	  *)
		echo "ERROR: Unable to determine client."
		exit 1
		;;
	  esac
	#Get tag name and remove leading 'v'
	TAG=$(curl -s $TAG_URL | jq -r .tag_name | sed 's/.*\(v[0-9]*\.[0-9]*\.[0-9]*\).*/\1/')
}

function updateClient(){
	case "$CLIENT" in
	  Lighthouse)
		[[ "${_arch}" == "amd64" ]] && _architecture="x86_64" || _architecture="aarch64"
		RELEASE_URL="https://api.github.com/repos/sigp/lighthouse/releases/latest"
		BINARIES_URL="$(curl -s $RELEASE_URL | jq -r ".assets[] | select(.name) | .browser_download_url" | grep --ignore-case ${_architecture}-unknown-${_platform}-gnu.tar.gz$)"
		echo Downloading URL: $BINARIES_URL
		cd $HOME
		wget -O lighthouse.tar.gz $BINARIES_URL
		if [ ! -f lighthouse.tar.gz ]; then
			echo "Error: Downloading lighthouse archive failed!"
			exit 1
		fi
		tar -xzvf lighthouse.tar.gz -C $HOME
		rm lighthouse.tar.gz
		test -f /etc/systemd/system/consensus.service && sudo systemctl stop consensus
		test -f /etc/systemd/system/validator.service && sudo service validator stop
		sudo rm /usr/local/bin/lighthouse
		sudo mv $HOME/lighthouse /usr/local/bin/lighthouse
		test -f /etc/systemd/system/consensus.service && sudo systemctl start consensus
		test -f /etc/systemd/system/validator.service && sudo service validator start
	    ;;
	  Lodestar)
		RELEASE_URL="https://api.github.com/repos/ChainSafe/lodestar/releases/latest"
		LATEST_TAG="$(curl -s $RELEASE_URL | jq -r ".tag_name")"
		BINARIES_URL="https://github.com/ChainSafe/lodestar/releases/download/${LATEST_TAG}/lodestar-${LATEST_TAG}-${_platform}-${_arch}.tar.gz"
		echo Downloading URL: $BINARIES_URL
		cd $HOME
		wget -O lodestar.tar.gz $BINARIES_URL
		if [ ! -f lodestar.tar.gz ]; then
			echo "Error: Downloading lodestar archive failed!"
			exit 1
		fi
		tar -xzvf lodestar.tar.gz -C $HOME
		rm lodestar.tar.gz
		test -f /etc/systemd/system/consensus.service && sudo systemctl stop consensus
		test -f /etc/systemd/system/validator.service && sudo service validator stop
		sudo rm -rf /usr/local/bin/lodestar
		sudo mkdir -p /usr/local/bin/lodestar
		sudo mv $HOME/lodestar /usr/local/bin/lodestar
		test -f /etc/systemd/system/consensus.service && sudo systemctl start consensus
		test -f /etc/systemd/system/validator.service && sudo service validator start
	    ;;
	  Teku)
		updateJRE
		RELEASE_URL="https://api.github.com/repos/ConsenSys/teku/releases/latest"
		LATEST_TAG="$(curl -s $RELEASE_URL | jq -r ".tag_name")"
		BINARIES_URL="https://artifacts.consensys.net/public/teku/raw/names/teku.tar.gz/versions/${LATEST_TAG}/teku-${LATEST_TAG}.tar.gz"
		echo Downloading URL: $BINARIES_URL
		cd $HOME
		wget -O teku.tar.gz $BINARIES_URL
		if [ ! -f teku.tar.gz ]; then
			echo "Error: Downloading teku archive failed!"
			exit 1
		fi
		tar -xzvf teku.tar.gz -C $HOME
		mv teku-${LATEST_TAG} teku
		rm teku.tar.gz
		test -f /etc/systemd/system/consensus.service && sudo systemctl stop consensus
		test -f /etc/systemd/system/validator.service && sudo service validator stop
		sudo rm -rf /usr/local/bin/teku
		sudo mv $HOME/teku /usr/local/bin/teku
		test -f /etc/systemd/system/consensus.service && sudo systemctl start consensus
		test -f /etc/systemd/system/validator.service && sudo service validator start
		;;
	  Nimbus)
	  	FIXED_VERSION=v25.4.1
		RELEASE_URL="https://api.github.com/repos/status-im/nimbus-eth2/releases/tags/${FIXED_VERSION}"
		BINARIES_URL="$(curl -s $RELEASE_URL | jq -r ".assets[] | select(.name) | .browser_download_url" | grep --ignore-case "_${_platform}_${_arch}.*.tar.gz$")"
		echo Downloading URL: $BINARIES_URL
		cd $HOME
		wget -O nimbus.tar.gz $BINARIES_URL
		if [ ! -f nimbus.tar.gz ]; then
			echo "Error: Downloading nimbus archive failed!"
			exit 1
		fi
		tar -xzvf nimbus.tar.gz -C $HOME
		mv nimbus-eth2_${_platform}_${_arch}* nimbus
		test -f /etc/systemd/system/consensus.service && sudo systemctl stop consensus
		test -f /etc/systemd/system/validator.service && sudo service validator stop
		sudo rm /usr/local/bin/nimbus_beacon_node
		sudo rm /usr/local/bin/nimbus_validator_client
		sudo mv nimbus/build/nimbus_beacon_node /usr/local/bin
		sudo mv nimbus/build/nimbus_validator_client /usr/local/bin
		test -f /etc/systemd/system/consensus.service && sudo systemctl start consensus
		test -f /etc/systemd/system/validator.service && sudo service validator start
		rm -r nimbus
		rm nimbus.tar.gz
	    ;;
  	  Prysm)
		cd $HOME
		prysm_version=$(curl -f -s https://prysmaticlabs.com/releases/latest)
		# Convert to lower case
		_platform=$(echo ${_platform} | tr '[:upper:]' '[:lower:]')
		file_beacon=beacon-chain-${prysm_version}-${_platform}-${_arch}
		file_validator=validator-${prysm_version}-${_platform}-${_arch}
		curl -f -L "https://prysmaticlabs.com/releases/${file_beacon}" -o beacon-chain
		curl -f -L "https://prysmaticlabs.com/releases/${file_validator}" -o validator
		chmod +x beacon-chain validator
		test -f /etc/systemd/system/consensus.service && sudo systemctl stop consensus
		test -f /etc/systemd/system/validator.service && sudo service validator stop
		sudo rm /usr/local/bin/beacon-chain
		sudo rm /usr/local/bin/validator
		sudo mv beacon-chain validator /usr/local/bin
		test -f /etc/systemd/system/consensus.service && sudo systemctl start consensus
		test -f /etc/systemd/system/validator.service && sudo service validator start
	    ;;
	  esac
}

function updateJRE(){
	# Check if OpenJDK-21-JRE or OpenJDK-21-JDK is already installed
	if dpkg --list | grep -q -E "openjdk-21-jre|openjdk-21-jdk"; then
	   echo "OpenJDK-21-JRE or OpenJDK-21-JDK is already installed. Skipping installation."
	else
	   # Install OpenJDK-21-JRE
	   sudo apt-get update
	   sudo apt-get install -y openjdk-21-jre

       # Check if the installation was successful
       if [ $? -eq 0 ]; then
	      echo "OpenJDK-21-JRE installed successfully!"
	   else
	      echo "Error installing OpenJDK-21-JRE. Please check the error log."
	   fi
	fi
}

setWhiptailColors
getClient
getCurrentVersion
getLatestVersion
promptYesNo