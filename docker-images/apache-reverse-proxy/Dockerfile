FROM php:7.4-apache

COPY apache2-foreground /usr/local/bin/
COPY conf/ /etc/apache2
COPY template/ /var/apache2/templates

RUN apt-get update && apt install nano


RUN a2enmod proxy proxy_http
RUN a2ensite 000-* 001-*
