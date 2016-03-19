#!/bin/bash
# Use bellow command:
# curl https://raw.githubusercontent.com/kimthangatm/servers_script/master/centos-6.7/init_server_api.sh | sh

#Config Color
BG_GREEN="\e[42m\e[97m"
BG_NC="\e[0m\n"

#Config db password
dbPassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 22 | head -n 1)

cd ~
curl -O http://vault.centos.org/RPM-GPG-KEY-CentOS-6

#Install base package
yum install -y wget nano git tree zip unzip tar man gcc gcc-c++ make

#Add repo
cd /etc/yum.repos.d
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
wget http://rpms.famillecollet.com/enterprise/remi.repo
wget https://raw.githubusercontent.com/kimthangatm/servers_script/master/centos-6.7/init_server_main_api/nginx.repo
rpm -Uvh epel-release-6*.rpm
echo "y" | yum --enablerepo=remi,remi-php56 install -y perl nginx redis mysql-server memcached php php-devel pcre-devel php-fpm php-pdo php-mcrypt php-redis php-gd php-xml php-recode php-mbstring php-mysql php-intl php-opcache php-pear php-pecl-memcache php-pecl-memcached php-apc libxml2-devel

sed -i '10i-A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT' /etc/sysconfig/iptables
sed -i '10i-A INPUT -p tcp -m state --state NEW -m tcp --dport 3052 -j ACCEPT' /etc/sysconfig/iptables
sed -i '11i-A INPUT -p tcp -m state --state NEW -m tcp --dport 3306 -j ACCEPT' /etc/sysconfig/iptables
setsebool -P httpd_can_network_connect 1

#Config MySQL
service mysqld start
/usr/bin/mysql_secure_installation << EOF

y
$dbPassword
$dbPassword
y
y
y
y
EOF
mysql --user="root" --password="$dbPassword" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$dbPassword';"
mysql --user="root" --password="$dbPassword" -e "CREATE DATABASE zcms COLLATE 'utf8_general_ci';"
service iptables restart

#Install phpMyAdmin
rm -fr /etc/nginx/conf.d/default.conf

chmod 755 /usr/share/nginx/html/
chcon -Rt httpd_sys_rw_content_t /usr/share/nginx/html/
echo "<?php echo phpinfo();" > /usr/share/nginx/html/index.php

rm -fr /etc/php.ini
cd /etc/
wget https://raw.githubusercontent.com/kimthangatm/servers_script/master/centos-6.7/init_server_main_api/php.ini
cd /etc/nginx/conf.d/
wget https://raw.githubusercontent.com/kimthangatm/servers_script/master/centos-6.7/init_server_main_api/api-demo.conf
cd /etc/php.d/
wget https://raw.githubusercontent.com/kimthangatm/servers_script/master/centos-6.7/init_server_main_api/60-phalcon.ini


#Install Phalcon
cd ~
wget https://github.com/phalcon/cphalcon/archive/phalcon-v2.0.10.tar.gz
tar vfx phalcon-v2.0.10.tar.gz
cd cphalcon-phalcon-v2.0.10/build/
./install
cd ~
rm -fr phalcon-v2.0.10.tar.gz
rm -fr cphalcon-phalcon-v2.0.10

chkconfig php-fpm on
chkconfig redis on
chkconfig nginx on
chkconfig mysqld on

service php-fpm start
service nginx start
service redis start
service mysqld start

#Clean YUM
yum clean all

cd ~
echo "---------------------------------------------------
-----------  INSTALL ZCMS SUCCESSFULLY  -----------
---------------------------------------------------
---------------------------------------------------
- DB INFO:                                        -
- DB USERNAME   : root                            -
- DB PASSWORD   : $dbPassword          -
- MySQL PASSWORD: $dbPassword          -
- Please change your password for mysql           -
===================================================
= WARNING: PLEASE REMEMBER AND REMOVE THIS FILE   =
===================================================" > install_info_db.txt

clean
history -cw

echo "---------------------------------------------------"
echo "---------------------------------------------------"
echo "-------------  INSTALL SUCCESSFULLY  --------------"
echo "---------------------------------------------------"
echo "---------------------------------------------------"
echo "- DB INFO:                                        -"
echo "- DB USERNAME   : root                            -"
echo "- DB PASSWORD   : $dbPassword          -"
echo "- MySQL PASSWORD: $dbPassword          -"
echo "- Please change your password for mysql           -"
echo "---------------------------------------------------"
echo "- READ INFO DATABASE:# nano ~\\install_info_db.txt-"
echo "---------------------------------------------------"