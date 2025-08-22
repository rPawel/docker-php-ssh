#!/bin/bash
CUR_LOCALE=${CTNR_LOCALE:-"en_GB.UTF-8"}
echo "Setting locale: ${CUR_LOCALE}"
locale-gen ${CUR_LOCALE}
update-locale LANG=${CUR_LOCALE} LC_MESSAGES=POSIX

CUR_TIMEZONE=${CTNR_TIMEZONE:-"Europe/London"}
echo "Setting timezone: ${CUR_TIMEZONE}"
echo ${CUR_TIMEZONE} > /etc/timezone; dpkg-reconfigure --frontend noninteractive tzdata

# Composer
EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
then
    >&2 echo 'ERROR: Invalid installer checksum'
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --quiet
RESULT=$?
rm composer-setup.php
mv composer.phar /usr/local/bin/composer
exit $RESULT