#Deploy on azure VM


#!/bin/bash

MYSQLIP=''
MYSQLUSER=''
MYSQLPASSWORD=''
MYSQLDB=''

sudo apt update
sudo apt upgrade

#APACHE2
sudo apt install -y apache2 apache2-utils
sudo systemctl start apache2
sudo systemctl enable apache2
sudo systemctl status apache2

#PYTHON3 + FLASK + RESTEN
sudo apt install python-flask
sudo apt install python3-pip
sudo apt install python-dev default-libmysqlclient-dev
sudo pip3 install flask-mysqldb
sudo apt install libapache2-mod-wsgi-py3

#MARIADB
echo "##################"
echo "WARNING USER INPUT"
echo "##################"
read -p "Type yes to install and configure a local mariaDB server, skip if you wanna use a remote server --> " userinput

if [[ $userinput == 'yes' ]]
then
	sudo apt install mariadb-server mariadb-client
	sudo systemctl start mariadb
	sudo systemctl enable mariadb
	systemctl status mariadb
	sudo mysql_secure_installation

	echo "##################"
	echo "WARNING USER INPUT"
	read -p "Enter mysqlhostIP: " MYSQLIP
	read -p "Enter mysqlUSER: " MYSQLUSER
	read -p "Enter mysqlPASSWORD: " MYSQLPASSWORD
	read -p "Enter mysqlDB: " MYSQLDB
	echo "#################"
	sudo mariadb -u root -p -e "CREATE DATABASE "$MYSQLDB"; USE "$MYSQLDB"; CREATE TABLE users(username varchar(75), password_hash varchar(512)); GRANT SELECT, INSERT ON "$MYSQLDB".* TO '"$MYSQLUSER"'@'"$MYSQLIP"' IDENTIFIED BY '"$MYSQLPASSWORD"'; FLUSH PRIVILEGES;"
fi

#GIT
cd ~
mkdir git
cd git
git init
git remote add github https://github.com/permabull/simplewebapp.git
git clone https://github.com/permabull/simplewebapp.git

sudo mkdir /var/www/html/flaskapp/

sudo cp -rv ~/git/simplewebapp/flaskapp /var/www/html/

#CREATE YAML FILE FOR SQL
touch db.yaml
echo "mysql_host: '$MYSQLIP'" >> db.yaml
echo "mysql_user: '$MYSQLUSER'" >> db.yaml
echo "mysql_password: '$MYSQLPASSWORD'" >> db.yaml
echo "mysql_db: '$MYSQLDB'" >> db.yaml

sudo mv db.yaml /var/www/html/flaskapp

sudo systemctl restart apache2

echo "##################"
echo "WARNING USER INPUT"
read -p "Enter domain: " SERVERNAME
echo "##################"

#PUT DATA IN APACHECONFIGFILE
sudo sed -i "/DocumentRoot/c\###" /etc/apache2/sites-available/000-default.conf
sudo sed -i "/ServerAdmin webmaster@localhost/c\###" /etc/apache2/sites-available/000-default.conf

sudo sed -i '13i     ServerAdmin tomten@website.com' /etc/apache2/sites-available/000-default.conf
sudo sed -i '14i     ServerName '$SERVERNAME'' /etc/apache2/sites-available/000-default.conf
sudo sed -i '15i     WSGIScriptAlias / /var/www/html/flaskapp/app.wsgi' /etc/apache2/sites-available/000-default.conf
sudo sed -i '16i     <Directory /var/www/html/flaskapp>' /etc/apache2/sites-available/000-default.conf
sudo sed -i '17i     Order allow,deny' /etc/apache2/sites-available/000-default.conf
sudo sed -i '18i     Allow from all' /etc/apache2/sites-available/000-default.conf
sudo sed -i '19i     </Directory>' /etc/apache2/sites-available/000-default.conf

#SSL CERT
sudo apt install python3-certbot-apache
sudo certbot -d $SERVERNAME





