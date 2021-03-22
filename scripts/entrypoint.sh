#!/bin/bash
sleep 10s
mysql -uroot <<MYSQL_SCRIPT
CREATE DATABASE zabbix;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'zabbix';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
mysql -uzabbix -pzabbix zabbix < schema.sql
service mysqld restart