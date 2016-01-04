FROM rpawel/ubuntu:trusty

RUN apt-get -q -y update \
 && apt-get dist-upgrade -y --no-install-recommends \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install openssh-server apg \
  php5 php5-cli php5-dev php-pear php5-common php5-apcu \
  php5-mcrypt php5-gd php5-mysql php5-curl php5-json php5-intl \
  php5-memcached php5-memcache \
  imagemagick graphicsmagick graphicsmagick-libmagick-dev-compat php5-imagick trimage \
  git subversion \
 && useradd -d /var/www/app --no-create-home --shell /bin/bash -g www-data -G adm user \
 && mkdir -p /var/run/sshd \
 && DEBIAN_FRONTEND=newt

ADD ./config /etc/

