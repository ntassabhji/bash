#!/bin/bash

echo "enter old foldername"
read __old_folder_name
echo "enter old apache config name"
read __old_apache_config

__db_old_name=$(sed -n 's/^ *MYSQL_DATABASE *= *//p' /var/www/$__old_folder_name/public/.env)
__old_apache_username=$(sed -n 's/^ *SuexecUserGroup * *//p' /etc/apache2/sites-enabled/$__old_apache_config.conf | awk '{ print $2 }')
__db_password=$(sed -n 's/^ *MYSQL_PASSWORD *= *//p' /var/www/$__old_folder_name/public/.env)


if [ -d /root/nawras ]
then
echo "folder nawras exists, skipping"
else
mkdir /root/nawras
fi


mysqldump -u root $__db_old_name -p > /root/nawras/$__db_old_name\.dump


tar -cvzf /root/nawras/$__old_folder_name.tar /var/www/$__old_folder_name/

cp /etc/apache2/sites-enabled/$__old_apache_config.conf /root/nawras/

echo $__db_old_name > /root/nawras/db_old_name
echo $__old_apache_username > /root/nawras/old_apache_username
echo $__db_password > /root/nawras/db_password