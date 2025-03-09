FROM rpawel/ubuntu:jammy

RUN apt -q -y update && \
    add-apt-repository ppa:ondrej/php -y && \
    apt -q -y update && \
    apt dist-upgrade -y --no-install-recommends && \
    DEBIAN_FRONTEND=noninteractive apt install -y -q --no-install-recommends \
    openssh-server apg php8.3 php8.3-cli php8.3-dev php8.3-common php8.3-apcu \
    php8.3-gd php8.3-mysql php8.3-curl php8.3-intl php8.3-xsl php8.3-ssh2 php8.3-mbstring \
    php8.3-zip php8.3-memcached php8.3-memcache php8.3-redis php8.3-xdebug php8.3-imap \
    php8.3-bcmath php8.3-soap \
    imagemagick graphicsmagick graphicsmagick-libmagick-dev-compat php8.3-imagick trimage \
    exim4 git locales && \
    phpdismod xdebug && \
    useradd -d /var/www/app --no-create-home --shell /bin/bash -g www-data -G adm user && \
    mkdir -p /var/run/sshd && \
    mkdir -p /var/log/supervisor

# Config
ADD ./config /etc/
RUN crontab -u user /etc/app.cron && \
    DEBIAN_FRONTEND=newt

ADD build.sh /
ADD run.sh /
RUN chmod +x /build.sh /run.sh && bash /build.sh && rm -f /build.sh

# PORTS
EXPOSE 22

ENTRYPOINT ["/run.sh"]
