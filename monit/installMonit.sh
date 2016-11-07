#!/bin/bash

# #############################################################################
# "This program may be used, executed, copied, modified and distributed without
# royalty for the purpose of developing, using, marketing, or distributing."
#
# IBM Cloud Performance
# (C) COPYRIGHT International Business Machines Corp., 2014-2015
# All Rights Reserved * Licensed Materials - Property of IBM
# #############################################################################

## This script will download and install monit (http://mmonit.com/monit/#download)
## sample run:
##     ./installMonit.sh
# foo

[ "$?" -ne "0" ] && { echo "ERROR: failed to install wget"; exit 1; }

if [ -z "${MONIT_VERSION+xxx}" ] || [ -z "${MONIT_VERSION}" -a "${MONIT_VERSION+xxx}" = "xxx" ]; then
	# MONIT_VERSION not specifiled; Install the latest version
	echo "MONIT_VERSION is not set or empty... will install the latest version found"
	# Construct download url

	MONIT_DL_HOME="https://mmonit.com/monit/dist/binary/"

	# Get versions available
	# NOTE: no "latest" pointer to newest version so scraping the download page for now
	scraped_versions=$(curl -sL ${MONIT_DL_HOME} | grep '\[DIR\]')
	[ "$?" -ne "0" ] && { echo "Failed to get versions"; exit 1; }

	versions=()

	for entry in ${scraped_versions}; do
		# parse versions
	    if [[ "${entry}" =~ ^href ]]; then
	        version="${entry#href=\"}"
	        version="${version%%\/*}"
	        versions+=("${version}")
	    fi
	done

	# Sort versions of monit
	sorted_versions=($(for each in ${versions[@]}; do echo $each; done | sort -rV))
	newest_version="${sorted_versions[0]}"
	[ "${newest_version}" == "" ] && { echo "Failed to identify latest version of Monit"; exit 1; }

	# set the monit version to download
	monit_version="${newest_version}"

else
	# Install the specified monit version
	monit_version="${MONIT_VERSION}"
fi

download_url="https://mmonit.com/monit/dist/binary/${monit_version}/monit-${monit_version}-linux-x64.tar.gz"

echo "Installing Monit v${monit_version}"
# Install monit in /opt
# Change directory to /opt
cd /opt

# Download monit tar
echo "Downloading Monit: ${download_url}"
#curl -LO "${download_url}"
wget ${download_url}
[ "$?" -ne "0" ] && { echo "ERROR: Failed to download monit."; exit 1; }
echo ""

monit_tar=$(basename ${download_url})

# Untar monit
echo "Untaring Monit [${monit_tar}]"
tar -zxvf ${monit_tar}
[ "$?" -ne "0" ] && { echo "ERROR: Failed to untar monit."; exit 1; }
echo ""

# Create sym link in bin
ln -s /opt/monit-${monit_version}/bin/monit /usr/bin/monit

# Remove TAR file
rm -f ${monit_tar}

echo "Monit download and extraction complete."
monit --version
echo ""
