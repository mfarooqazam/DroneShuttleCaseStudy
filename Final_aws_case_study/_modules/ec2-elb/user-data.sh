#!/bin/bash -xe
DB_NAME=${DB_NAME}
DB_HOSTNAME=${DB_HOSTNAME}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}
WP_ADMIN=${WP_ADMIN}
WP_PASSWORD=${WP_PASSWORD}
WP_EMAIL=${WP_EMAIL}
LB_HOSTNAME=${LB_HOSTNAME}
EFSMOUNTID=${EFSMOUNTID}
AWSREGION=${AWSREGION}
yum update -y
yum install -y amazon-linux-extras
yum install -y awslogs httpd mysql gcc-c++
amazon-linux-extras enable php7.4
yum clean metadata
yum install -y php php-{pear,cgi,common,curl,mbstring,gd,mysqlnd,gettext,bcmath,json,xml,fpm,intl,zip,imap,devel,opcache}
systemctl enable nfs-server.service
systemctl start nfs-server.service
mkdir -p /var/www/wordpress
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 "$EFSMOUNTID".efs."$AWSREGION".amazonaws.com:/ /var/www/wordpress

## create site config
cat <<EOF >/etc/httpd/conf.d/wordpress.conf
ServerName 127.0.0.1:80
DocumentRoot /var/www/wordpress
<Directory /var/www/wordpress>
Options Indexes FollowSymLinks
AllowOverride All
Require all granted
</Directory>
EOF

## install cache client
pecl install igbinary
wget -P /tmp/ https://elasticache-downloads.s3.amazonaws.com/ClusterClient/PHP-7.4/latest-64bit-X86
cd /tmp
tar -zxvf latest-64bit-X86
cp '/tmp/amazon-elasticache-cluster-client.so' /usr/lib64/php/modules/
if [ ! -f /etc/php.d/50-memcached.ini ]; then
    touch /etc/php.d/50-memcached.ini
fi
echo 'extension=igbinary.so;' >> /etc/php.d/50-memcached.ini
echo 'extension=/usr/lib64/php/modules/amazon-elasticache-cluster-client.so;' >> /etc/php.d/50-memcached.ini

## install WordPress and WP CLI
curl -o /bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /bin/wp
wget -P /tmp/ https://wordpress.org/latest.tar.gz
tar -vxzf latest.tar.gz -C /var/www/
cp /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php
cd /var/www/wordpress/
sed -i 's/database_name_here/'"$DB_NAME"'/' wp-config.php
sed -i 's/username_here/'"$DB_USERNAME"'/' wp-config.php
sed -i 's/password_here/'"$DB_PASSWORD"'/' wp-config.php
sed -i 's/localhost/'"$DB_HOSTNAME"'/' wp-config.php

# install WordPress if not installed
# use public alb host name if wp domain name was empty
if ! $(wp core is-installed --allow-root); then
    wp core install --url="http://$LB_HOSTNAME" --title='Wordpress on AWS' --admin_user="$WP_ADMIN" --admin_password="$WP_PASSWORD" --admin_email="$WP_EMAIL" --allow-root
    wp plugin install w3-total-cache --allow-root
    chown -R apache:apache /var/www/wordpress
    chmod u+wrx /var/www/wordpress/wp-content/*
    if [ ! -f /var/www/wordpress/opcache-instanceid.php ]; then
    wget -P /var/www/wordpress/ https://s3.amazonaws.com/aws-refarch/wordpress/latest/bits/opcache-instanceid.php
    fi
fi
RESULT=$?
echo $RESULT
if [ $RESULT -eq 0 ]; then
    touch /var/www/wordpress/wordpress.initialized
else
    touch /var/www/wordpress/wordpress.failed
fi

## install opcache
# create hidden opcache directory locally & change owner to apache

mkdir -p /var/www/.opcache
# enable opcache in /etc/php-7.0.d/10-opcache.ini
sed -i 's/;opcache.file_cache=.*/opcache.file_cache=\/var\/www\/.opcache/' /etc/php.d/10-opcache.ini
sed -i 's/opcache.memory_consumption=.*/opcache.memory_consumption=512/' /etc/php.d/10-opcache.ini
# download opcache-instance.php to verify opcache status
if [ ! -f /var/www/wordpress/opcache-instanceid.php ]; then
    wget -P /var/www/wordpress/ https://s3.amazonaws.com/aws-refarch/wordpress/latest/bits/opcache-instanceid.php
fi

#
# This script configures WordPress file permissions based on recommendations
# from http://codex.wordpress.org/Hardening_WordPress#File_permissions
#
# execute it with the following command:
# bash set-wordpress-permissions.sh /var/www/<site_folder>
#
OWNER=apache # <-- wordpress owner
GROUP=apache # <-- wordpress group
ROOT='/var/www/wordpress' # <-- wordpress root directory
 
# reset to safe defaults
find "$ROOT" -exec chown "$OWNER":"$GROUP" {} \;
find "$ROOT" -type d -exec chmod 755 {} \;
find "$ROOT" -type f -exec chmod 644 {} \;
 
# allow wordpress to manage wp-config.php (but prevent world access)
chgrp "$GROUP" "$ROOT"/wp-config.php
chmod 660 "$ROOT"/wp-config.php
 
# allow wordpress to manage wp-content
find "$ROOT"/wp-content -exec chgrp "$GROUP" {} \;
find "$ROOT"/wp-content -type d -exec chmod 775 {} \;
find "$ROOT"/wp-content -type f -exec chmod 664 {} \;

chkconfig httpd on
service httpd start