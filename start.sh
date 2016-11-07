#!/bin/bash

# #############################################################################
# "This program may be used, executed, copied, modified and distributed without
# royalty for the purpose of developing, using, marketing, or distributing."
#
# IBM Cloud Performance
# (C) COPYRIGHT International Business Machines Corp., 2014-2015
# All Rights Reserved * Licensed Materials - Property of IBM
# ##############################################################################

# Start script for main monit process

# Uncomment for debug
#env

# Check and remove monit pid file if it exists
[ -f "${MONIT_PID}" ] && rm ${MONIT_PID}

term_handler() {
  monit stop all
  exit 0
}
trap 'kill ${!}; term_handler' SIGTERM

# Start monit
#General Options and Arguments
#-c file Use this control file
#-d n Run as a daemon once per n seconds
#-g Set group name for start, stop, restart, monitor and unmonitor.
#-l logfile Print log information to this file
#-p pidfile Use this lock file in daemon mode
#-s statefile Write state information to this file
#-I Do not run in background (needed for run from init)
#-t Run syntax check for the control file
#-v Verbose mode, work noisy (diagnostic output)
#-H [filename] Print MD5 and SHA1 hashes of the file or of stdin if the filename is omitted; Monit will exit afterwards
#-V Print version number and patch level
#-h Print a help text

#monit -d 1 -I
monit -d 1

while true; do
  tail -f /var/log/monit/monit.log & wait ${!}
done
