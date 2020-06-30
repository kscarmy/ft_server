# Image source :
FROM debian:buster

# Installations des ressources en lignes :
RUN apt-get -y update \
&& apt-get -y install vim \
&& apt-get -y install wget \
&& apt-get -y install nginx \
&& apt-get -y install mariadb-server \
&& apt-get -y install procps \
&& apt-get -y install php7.3-fpm php7.3-common php7.3-mysql php7.3-gmp php7.3-curl php7.3-intl php7.3-mbstring php7.3-xmlrpc php7.3-gd php7.3-xml php7.3-cli php7.3-zip php7.3-soap php7.3-imap

# Installation des ressources locales :
COPY ./srcs/nginx-conf ./tmp/nginx-conf
COPY ./srcs/phpmyadmin.inc.php ./tmp/phpmyadmin.inc.php
COPY ./srcs/wp-config.php ./tmp/wp-config.php

# Fichiers :
RUN service mysql start \
&& chown -R www-data /var/www/* && chmod -R 755 /var/www/* \
&& mkdir /var/www/guderram && touch /var/www/guderram/index.php \
&& echo "<?php phpinfo(); ?>" >> /var/www/guderram/index.php

# Generation SSL :
RUN mkdir /etc/nginx/ssl \
&& openssl req -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out /etc/nginx/ssl/guderram.pem -keyout /etc/nginx/ssl/guderram.key -subj "/C=FR/ST=Paris/L=Paris/O=42 School/OU=rchallie/CN=guderram"

# Config nginx :
RUN mv ./tmp/nginx-conf /etc/nginx/sites-available/guderram \
&& ln -s /etc/nginx/sites-available/guderram /etc/nginx/sites-enabled/guderram \
&& rm -rf /etc/nginx/sites-enabled/default

# Config MYSQL
RUN service mysql restart \
&& echo "CREATE DATABASE wordpress;" | mysql -u root --skip-password \
&& echo "GRANT ALL PRIVILEGES ON wordpress.* TO 'root'@'localhost' WITH GRANT OPTION;" | mysql -u root --skip-password \
&& echo "update mysql.user set plugin='mysql_native_password' where user='root';" | mysql -u root --skip-password \
&& echo "FLUSH PRIVILEGES;" | mysql -u root --skip-password

# DL phpmyadmin
RUN mkdir /var/www/guderram/phpmyadmin \
&& wget https://files.phpmyadmin.net/phpMyAdmin/4.9.0.1/phpMyAdmin-4.9.0.1-all-languages.tar.gz \
&& tar -xvf phpMyAdmin-4.9.0.1-all-languages.tar.gz --strip-components 1 -C /var/www/guderram/phpmyadmin \
&& mv ./tmp/phpmyadmin.inc.php /var/www/guderram/phpmyadmin/config.inc.php

# DL wordpress
RUN cd /tmp/ \
&& wget -c https://wordpress.org/latest.tar.gz \
&& tar -xvzf latest.tar.gz \
&& mv wordpress/ /var/www/guderram \
&& mv /tmp/wp-config.php /var/www/guderram/wordpress

# Demarrages services :
RUN service mysql restart \
&& service php7.3-fpm start \
&& nginx -t \
&& service nginx start