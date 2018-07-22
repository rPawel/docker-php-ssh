FROM rpawel/ubuntu:trusty

RUN apt-get -q -y update \
 && apt-get dist-upgrade -y --no-install-recommends \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install openssh-server apg \
  php5 php5-cli php5-dev php-pear php5-common php5-apcu \
  php5-mcrypt php5-gd php5-mysql php5-curl php5-json php5-intl php5-xsl libssh2-php \
  php5-memcached php5-memcache php-xdebug php-imap \
  imagemagick graphicsmagick graphicsmagick-libmagick-dev-compat php5-imagick trimage \
  exim4 git subversion \
 && php5enmod mcrypt && php5enmod imap && phpdismod xdebug \
 && useradd -d /var/www/app --no-create-home --shell /bin/bash -g www-data -G adm user \
 && mkdir -p /var/run/sshd \
 && DEBIAN_FRONTEND=newt

ADD ./config /etc/
ADD run.sh /
ADD build.sh /

RUN update-exim4.conf \
 && crontab -u user /etc/app.cron \
 && chmod +x /build.sh /run.sh \
 && bash /build.sh && rm -rf /build.sh \
 && DEBIAN_FRONTEND=newt

# PORTS
EXPOSE 22

ENTRYPOINT ["/run.sh"]
