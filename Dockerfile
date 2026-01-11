FROM php:8.4-fpm-bookworm

ARG COMPOSER_VERSION=2.9.3

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    ffmpeg \
    git \
    libmagickwand-6.q16-6 \
    libmagickcore-6.q16-6 \
    libmagickwand-dev \
    $PHPIZE_DEPS \
  ; \
  \
  docker-php-ext-install pdo_mysql; \
  pecl install imagick; \
  docker-php-ext-enable imagick; \
  \
  curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php; \
  EXPECTED_SIG="$(curl -fsSL https://composer.github.io/installer.sig)"; \
  ACTUAL_SIG="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"; \
  [ "$EXPECTED_SIG" = "$ACTUAL_SIG" ]; \
  php /tmp/composer-setup.php --no-interaction --version="$COMPOSER_VERSION" --install-dir=/usr/local/bin --filename=composer; \
  composer --version; \
  rm -f /tmp/composer-setup.php; \
  \
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
