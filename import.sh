#!/bin/bash

echo "enter new username"
read __username
echo "enter new DB name"
read __db_name
echo "enter new foldername"
read __folder_name
echo "enter new apache config name"
read __apache_config

echo "enter old foldername"
read __old_folder_name
echo "enter old apache config name"
read __old_apache_config

__db_old_name=$(cat /root/nawras/db_old_name)
__old_apache_username=$(cat /root/nawras/old_apache_username)
__db_password=$(cat /root/nawras/db_password)


if [ -d /root/nawras ]
then
echo "folder nawras exists, skipping"
else
mkdir /root/nawras
fi

if [ -d /var/www/$__folder_name ]
then
echo "folder $__folder_name exists, stoping"
exit 0
else
mkdir /var/www/$__folder_name
fi


mysql -u root -p -e "CREATE USER '$__username'@'localhost' IDENTIFIED BY '$__db_password';"
mysql -u root -p -e "CREATE DATABASE $__db_name;"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON $__db_name.* TO '$__username'@'localhost';"
mysql -u root -p -e "FLUSH PRIVILEGES;"
mysql -u root -p $__db_name < /root/nawras/$__db_old_name\.dump

useradd $__username
passwd -l $__username
gpasswd -a www-data $__username
tar -xvf /root/nawras/$__old_folder_name.tar -C /var/www/$__folder_name --strip-components=3
chown -R $__username:$__username /var/www/$__folder_name
chmod -R 770 /var/www/$__folder_name
chmod -R 740 /var/www/$__folder_name/log/
chmod -R 750 /var/www/$__folder_name/php-fcgi/
echo "* * * * *       $__username cd /var/www/$__folder_name/public; drush cron --yes --quiet > /dev/null 2>&1" >> /etc/crontab


cp /root/nawras/$__old_apache_config.conf /etc/apache2/sites-enabled/$__apache_config.conf
sed -i "s/$__old_folder_name/$__folder_name/g" /etc/apache2/sites-enabled/$__apache_config.conf
sed -i "s/$__old_apache_username/$__username/g" /etc/apache2/sites-enabled/$__apache_config.conf

sed -i "s/$__old_folder_name/$__folder_name/g" /var/www/$__folder_name/conf/php.ini
sed -i "s/$__old_folder_name/$__folder_name/g" /var/www/$__folder_name/php-fcgi/php-fcgi-starter
sed -i "s/$__old_folder_name/$__folder_name/g" /var/www/$__folder_name/public/.env
sed -i "s/$__db_old_name/$__db_name/g" /var/www/$__folder_name/public/.env

echo "/var/www/$__folder_name/log/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 $__username root
    sharedscripts
    prerotate
        if [ -d /etc/logrotate.d/httpd-prerotate ]; then
            run-parts /etc/logrotate.d/httpd-prerotate
        fi
    endscript
    postrotate
        if pgrep -f ^/usr/sbin/apache2 > /dev/null; then
            invoke-rc.d apache2 reload 2>&1 | logger -t apache2.logrotate
        fi
    endscript
}" > /etc/logrotate.d/$__folder_name

logrotate --force /etc/logrotate.d/$__folder_name

service apache2 reload

certbot -d $__folder_name