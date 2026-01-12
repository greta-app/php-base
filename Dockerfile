FROM php:8.4-fpm-bookworm

ARG COMPOSER_VERSION=2.9.3

# 1) System deps (slow step; keep separate)
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    ffmpeg \
    git \
    \
    # common build deps for PHP extensions
    libcurl4-openssl-dev \
    libonig-dev \
    libzip-dev \
    zlib1g-dev \
    libxml2-dev \
    $PHPIZE_DEPS \
    \
    # GD
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    \
    # intl
    libicu-dev \
    \
    # ldap
    libldap2-dev \
    \
    # tidy
    libtidy-dev \
    \
    # xsl
    libxslt1-dev \
    \
    # bz2
    libbz2-dev \
    \
    # gettext runtime/tools
    gettext \
    \
    # imagick
    libmagickwand-6.q16-6 \
    libmagickcore-6.q16-6 \
    libmagickwand-dev \
  ; \
  rm -rf /var/lib/apt/lists/*

# 2) Configure + install PHP core extensions (fast-ish; isolated)
RUN set -eux; \
  docker-php-ext-configure gd --with-freetype --with-jpeg; \
  docker-php-ext-install -j"$(nproc)" \
    pdo_mysql \
    gd \
    curl \
    mbstring \
    zip \
    bcmath \
    bz2 \
    calendar \
    exif \
    ftp \
    gettext \
    intl \
    ldap \
    mysqli \
    pcntl \
    soap \
    sockets \
    tidy \
    xsl \
  ;

# 3) PECL extensions (separate so it won’t redo ext installs)
RUN set -eux; \
  pecl install imagick; \
  docker-php-ext-enable imagick;

# 4) Composer install (separate so failures don’t redo builds)
RUN set -eux; \
  curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php; \
  EXPECTED_SIG="$(curl -fsSL https://composer.github.io/installer.sig)"; \
  ACTUAL_SIG="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"; \
  [ "$EXPECTED_SIG" = "$ACTUAL_SIG" ]; \
  php /tmp/composer-setup.php --no-interaction --version="$COMPOSER_VERSION" \
    --install-dir=/usr/local/bin --filename=composer; \
  composer --version; \
  rm -f /tmp/composer-setup.php;

# 5) Cleanup build deps (optional; keep separate)
RUN set -eux; \
  apt-get update; \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    $PHPIZE_DEPS \
    libmagickwand-dev \
  ; \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "memory_limit=-1" > /usr/local/etc/php/conf.d/zz-custom.ini

RUN set -eux; \
  groupadd -g 1000 ec2-user; \
  useradd -u 1000 -g 1000 -m -s /bin/bash ec2-user

ENV COMPOSER_HOME=/tmp/composer
USER 1000
