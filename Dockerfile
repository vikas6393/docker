# Version 2.3
FROM ubuntu:bionic
MAINTAINER Bernardo Gomez Palacio <bernardo.gomezpalacio@gmail.com>
ENV REFRESHED_AT 2015-03-19
ARG APT_FLAGS_COMMON="-y"
ARG APT_FLAGS_PERSISTENT="${APT_FLAGS_COMMON} --no-install-recommends"
ARG APT_FLAGS_DEV="${APT_FLAGS_COMMON} --no-install-recommends"
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 TERM=xterm \
    MIBDIRS=/var/lib/snmp/mibs/ietf:/var/lib/snmp/mibs/iana:/usr/share/snmp/mibs:/var/lib/zabbix/mibs MIBS=+ALL 

RUN set -eux && \
    apt-get ${APT_FLAGS_COMMON} update && \
    DEBIAN_FRONTEND=noninteractive apt-get ${APT_FLAGS_PERSISTENT} install locales && \
    locale-gen $LC_ALL && \
    echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d && \
    addgroup --system --quiet zabbix && \
    adduser --quiet \
            --system --disabled-login \
            --ingroup zabbix \
            --home /var/lib/zabbix/ \
        zabbix && \
    usermod -G zabbix,dialout zabbix && \
    mkdir -p /etc/zabbix && \
    chown --quiet -R zabbix:root /var/lib/zabbix && \
    apt-get ${APT_FLAGS_COMMON} update && \
     DEBIAN_FRONTEND=noninteractive apt-get ${APT_FLAGS_PERSISTENT} install \
            iputils-ping \
            traceroute \
            fping \
            wget \
            libcurl4 \
            libevent-2.1 \
            libiksemel3 \
            libopenipmi0 \
            libpcre3 \
            libssh2-1 \
            libssl1.1 \
            libxml2 \
            mysql-server \
            mysql-client \
            snmp-mibs-downloader \
            ca-certificates \
            unixodbc && \
    apt-get ${APT_FLAGS_COMMON} autoremove && \
    rm -rf /var/lib/apt/lists/* 

RUN wget https://repo.zabbix.com/zabbix/4.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.2-2+bionic_all.deb && \
    dpkg -i zabbix-release_4.2-2+bionic_all.deb && \
    apt-get update && \
    apt install -y zabbix-proxy-mysql && \
    apt install -y zabbix-agent

# MySQL
COPY ./mysql/my.cnf /etc/mysql/conf.d/my.cnf
# Get the tuneup kit
# https://major.io/mysqltuner/

COPY ./sudoers.d/    /etc/sudoers.d/
# Zabbix Conf Files
COPY ./zabbix/zabbix-agentd.conf 		    /etc/zabbix/zabbix_agentd.conf
COPY ./zabbix/zabbix-proxy.conf 		    /etc/zabbix/zabbix_proxy.conf

RUN chmod 640 /etc/zabbix/zabbix_proxy.conf
RUN chown root:zabbix /etc/zabbix/zabbix_proxy.conf

# Add the script that will start the repo.
ADD ./scripts/entrypoint.sh /bin/zabbix
RUN chmod 755 /bin/zabbix

# Expose the Ports used by
# * Zabbix services
# * Apache with Zabbix UI
# * Monit
EXPOSE 10051 10050 80 3306

VOLUME ["/var/lib/mysql", "/usr/lib/zabbix/alertscripts", "/usr/lib/zabbix/externalscripts","/etc/zabbix/zabbix_proxy.d","/etc/zabbix/zabbix_agentd.d"]

ENTRYPOINT ["/usr/sbin/zabbix_proxy"]