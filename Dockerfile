FROM rpawel/ubuntu:jammy

RUN apt -q -y update && \
    add-apt-repository ppa:ondrej/php -y && \
    apt -q -y update && \
    apt dist-upgrade -y --no-install-recommends && \
    DEBIAN_FRONTEND=noninteractive apt install -y -q --no-install-recommends \
    openssh-server apg php8.2 php8.2-cli php8.2-dev php8.2-common php8.2-apcu \
    php8.2-gd php8.2-mysql php8.2-curl php8.2-intl php8.2-xsl php8.2-ssh2 php8.2-mbstring \
    php8.2-zip php8.2-memcached php8.2-memcache php8.2-redis php8.2-xdebug php8.2-imap \
    php8.2-bcmath php8.2-soap \
    imagemagick graphicsmagick graphicsmagick-libmagick-dev-compat php8.2-imagick trimage \
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
