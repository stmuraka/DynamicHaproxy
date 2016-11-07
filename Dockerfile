# #############################################################################
# "This program may be used, executed, copied, modified and distributed without
# royalty for the purpose of developing, using, marketing, or distributing."
#
# IBM Cloud Performance
# (C) COPYRIGHT International Business Machines Corp., 2014-2015
# All Rights Reserved * Licensed Materials - Property of IBM
# ##############################################################################

# This Dockerfile creates a HaPrroxy dynamic load balancer container
# The load balancer config is generated by confd based off the keys stored in Redis

FROM ubuntu:xenial
MAINTAINER Shaun Murakami <stmuraka@us.ibm.com>

ARG CONTAINER_TIMEZONE
ENV CONTAINER_TIMEZONE ${CONTAINER_TIMEZONE:-"America/Los_Angeles"}

ARG HAPROXY_VERSION
ENV HAPROXY_VERSION ${HAPROXY_VERSION:-1.6}

# We don't use the defaut package from ubuntu as it is outdated
# Use alternative repo
RUN echo "deb http://ppa.launchpad.net/vbernat/haproxy-${HAPROXY_VERSION}/ubuntu `cat /etc/lsb-release | grep CODENAME | cut -d '=' -f2` main" > /etc/apt/sources.list.d/vbernat-haproxy.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv 1C61B9CD

# Update container
RUN apt-get update \
 && apt-get dist-upgrade -y \
 && apt-get install -y \
## Add other packages here
    openssl \
    wget \
    curl \
    net-tools \
    vim \
## optional packages
    iputils-ping \
    haproxy \
    rsyslog \
    redis-server \

# Cleanup package files
 && apt-get autoremove \
 && apt-get autoclean

# Fix timezone
RUN rm -f /etc/localtime \
 && ln -s /usr/share/zoneinfo/${CONTAINER_TIMEZONE} /etc/localtime

ENV TERM="xterm"

WORKDIR /root

#------------------
# Confd
#------------------
ARG CONFD_VERSION
ENV CONFD_VERSION="${CONFD_VERSION}"
ENV CONFD_CONF_DIR="/etc/confd/conf.d" \
    CONFD_TEMP_DIR="/etc/confd/templates"
COPY confd/installConfd.sh /root/
COPY confd/confdctl /usr/bin/
# Install confd
RUN /root/installConfd.sh && rm /root/installConfd.sh

#------------------
# Monit (process manager)
#------------------
ARG MONIT_VERSION
ENV MONIT_VERSION="${MONIT_VERSION}"
EXPOSE 2812
COPY monit/installMonit.sh /root/

# Install & Configure monit
ENV MONITRC="/etc/monitrc" \
    MONIT_CONF_DIR="/etc/monit/conf.d" \
    MONIT_LOG="/var/log/monit/monit.log" \
    MONIT_PID="/var/run/monit.pid" \
    MONIT_ID="/var/lib/monit/id" \
    MONIT_STATE="/var/lib/monit/state"

RUN /root/installMonit.sh \
 && rm /root/installMonit.sh \
 && mkdir -p ${MONIT_CONF_DIR} \
 && mkdir -p `dirname ${MONIT_LOG}` \
 && mkdir -p `dirname ${MONIT_ID}` \
 && echo 'include '${MONIT_CONF_DIR}'/*' >> ${MONITRC} \
 && echo '' >> ${MONITRC} \
 && echo 'set httpd' >> ${MONITRC} \
 && echo '    port 2812' >> ${MONITRC} \
 && echo '    allow monit:monit' >> ${MONITRC} \
 && echo '' >> ${MONITRC} \
 && echo 'set pidfile '${MONIT_PID} >> ${MONITRC} \
 && echo 'set logfile '${MONIT_LOG} >> ${MONITRC} \
 && echo 'set idfile '${MONIT_ID} >> ${MONITRC} \
 && echo 'set statefile '${MONIT_STATE} >> ${MONITRC} \
 && chmod 700 ${MONITRC}

# Copy monit configs
COPY monit/conf.d/* ${MONIT_CONF_DIR}/
RUN chmod 700 ${MONIT_CONF_DIR}/

# Copy Confd templates
COPY confd/conf.d/* ${CONFD_CONF_DIR}/
COPY confd/templates/* ${CONFD_TEMP_DIR}/

#------------------
# HAproxy
#------------------
# Copy haproxyctl script
EXPOSE 1936
RUN mkdir -p /var/run/haproxy/ \
 && mkdir -p /var/log/haproxy/ \
 && cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig
# Setup logging
RUN sed -i -e '/^#.*imudp.*/s/^#//g' /etc/rsyslog.conf \
 && sed -i -e '/^input.*imudp.*/a$AllowedSender UDP, 127.0.0.1' /etc/rsyslog.conf

#------------------
# Redis
#------------------
EXPOSE 6379
#RUN mv /etc/redis/redis.conf /etc/redis/redis.conf.orig
#COPY redis/redis.conf /etc/redis/

# bind to all interfaces
RUN sed -i -e 's/^bind .*/bind 0\.0\.0\.0/' /etc/redis/redis.conf

#------------------
# Discovery
#------------------
COPY discovery/discoveryctl /usr/bin/

COPY start.sh /root/
CMD /root/start.sh
