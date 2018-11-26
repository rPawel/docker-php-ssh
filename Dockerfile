FROM rpawel/ubuntu:bionic

RUN apt-get -q -y update \
 && apt-get dist-upgrade -y --no-install-recommends \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install openssh-server apg \
  php php-cli php-dev php-pear php-common php-apcu \
  php-gd php-mysql php-curl php-json php-intl php-xsl php-ssh2 php-mbstring \
  php-zip php-memcached php-memcache php-xdebug php-imap \
  imagemagick graphicsmagick graphicsmagick-libmagick-dev-compat php-imagick trimage \
  exim4 git subversion \
 && phpenmod mcrypt && phpenmod imap && phpdismod xdebug \
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
