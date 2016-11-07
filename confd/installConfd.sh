#!/bin/bash

# #############################################################################
# "This program may be used, executed, copied, modified and distributed without
# royalty for the purpose of developing, using, marketing, or distributing."
#
# IBM Cloud Performance
# (C) COPYRIGHT International Business Machines Corp., 2014-2015
# All Rights Reserved * Licensed Materials - Property of IBM
# #############################################################################

## This script will download and install confd (https://github.com/kelseyhightower/confd/releases/)
## Latest test with confd_version="0.11"
## sample run:
##     ./installConfd.sh

# Uncomment (CONFD_VERSION) and specify the confd version below to override the version that will be installed.
# If no version is specified the latest version found will be installed
#CONFD_VERSION=0.11.0

if [ -z "${CONFD_VERSION+xxx}" ] || [ -z "${CONFD_VERSION}" -a "${CONFD_VERSION+xxx}" = "xxx" ]; then
	# CONFD_VERSION not specifiled; Install the latest version
	echo "CONFD_VERSION is not set or empty... will install the latest version found"
	# Construct download url
	scraped_url=$(curl -sL https://github.com/kelseyhightower/confd/releases/latest | grep 'linux-amd64"' | head -n 1 | awk '{print $2}')
	download_url="${scraped_url#href=\"}"
	download_url="https://github.com${download_url%%\"}"
	confd_version="${download_url#*\/confd-}"
	confd_version="${confd_version%%-linux-amd64}"
else
	# Install the specified confd version
	confd_version="${CONFD_VERSION}"
	echo "CONFD_VERSION=${CONFD_VERSION}"
	download_url="https://github.com/kelseyhightower/confd/releases/download/v${confd_version}/confd-${confd_version}-linux-amd64"
fi

confd_bin=$(basename ${download_url})

# Download to /tmp
cd /tmp

# Download confd
echo "Downloading confd ${confd_version}: ${download_url}"
wget "${download_url}"
[ "$?" -ne "0" ] && { echo "ERROR: Failed to download confd."; exit 1; }
echo ""

# Copy downloaded confd bin to the bin dir
chmod 755 ./${confd_bin}
mv ./${confd_bin} /usr/bin/confd
[ "$?" -ne "0" ] && { echo "ERROR: Moving confd to /usr/bin/ failed"; exit 1; }
echo ""

# Create config dirs for confd
CONFD_CONF_DIR=${CONFD_CONF_DIR:-/etc/confd/conf.d}
CONFD_TEMP_DIR=${CONFD_TEMP_DIR:-/etc/confd/templates}
mkdir -p ${CONFD_CONF_DIR}
mkdir -p ${CONFD_TEMP_DIR}
mkdir -p /var/run/confd
mkdir -p /var/log/confd


echo "confd download and installation complete."
confd -version
echo ""

# Start with: confd -backend etcd -node 127.0.0.1:4001
