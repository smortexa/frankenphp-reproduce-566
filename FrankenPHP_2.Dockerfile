# Accepted values: 8.3 - 8.2
ARG PHP_VERSION=8.3

ARG FRANKENPHP_VERSION=1.1-php${PHP_VERSION}

ARG COMPOSER_VERSION=latest

###########################################
# Build frontend assets with NPM
###########################################

###########################################

FROM composer:${COMPOSER_VERSION} AS vendor

FROM dunglas/frankenphp:${FRANKENPHP_VERSION} AS server

FROM php:${PHP_VERSION}-cli-bookworm

LABEL maintainer="SMortexa <seyed.me720@gmail.com>"
LABEL org.opencontainers.image.title="Laravel Octane Dockerfile"
LABEL org.opencontainers.image.description="Production-ready Dockerfile for Laravel Octane"
LABEL org.opencontainers.image.source=https://github.com/exaco/laravel-octane-dockerfile
LABEL org.opencontainers.image.licenses=MIT

ARG WWWUSER=1000
ARG WWWGROUP=1000
ARG TZ=UTC

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-color \
    WITH_HORIZON=false \
    WITH_SCHEDULER=false \
    OCTANE_SERVER=frankenphp \
    USER=octane \
    ROOT=/var/www/html \
    COMPOSER_FUND=0 \
    COMPOSER_MAX_PARALLEL_HTTP=24

WORKDIR ${ROOT}

SHELL ["/bin/bash", "-eou", "pipefail", "-c"]

RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN apt-get update; \
    apt-get upgrade -yqq; \
    apt-get install -yqq --no-install-recommends --show-progress \
    apt-utils \
    curl \
    wget \
    nano \
    ncdu \
    ca-certificates \
    supervisor \
    libsodium-dev \
    # Install PHP extensions
    && install-php-extensions \
    bz2 \
    pcntl \
    mbstring \
    bcmath \
    sockets \
    pgsql \
    pdo_pgsql \
    opcache \
    exif \
    pdo_mysql \
    zip \
    intl \
    gd \
    redis \
    rdkafka \
    memcached \
    igbinary \
    ldap \
    && apt-get -y autoremove \
    && apt-get clean \
    && docker-php-source delete \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && rm /var/log/lastlog /var/log/faillog

RUN wget -q "https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-amd64" \
    -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic \
    && mkdir -p /etc/supercronic \
    && echo "*/1 * * * * php ${ROOT}/artisan schedule:run --verbose --no-interaction" > /etc/supercronic/laravel

RUN userdel --remove --force www-data \
    && groupadd --force -g ${WWWGROUP} ${USER} \
    && useradd -ms /bin/bash --no-log-init --no-user-group -g ${WWWGROUP} -u ${WWWUSER} ${USER}

RUN chown -R ${USER}:${USER} ${ROOT} /var/{log,run} \
    && chmod -R a+rw /var/{log,run}

RUN cp ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini

USER ${USER}

COPY --chown=${USER}:${USER} --from=vendor /usr/bin/composer /usr/bin/composer
COPY --chown=${USER}:${USER} composer.json composer.lock ./

RUN composer install \
    --no-dev \
    --no-interaction \
    --no-autoloader \
    --no-ansi \
    --no-scripts \
    --audit

COPY --chown=${USER}:${USER} . .

RUN mkdir -p \
    storage/framework/{sessions,views,cache,testing} \
    storage/logs \
    bootstrap/cache && chmod -R a+rw storage

# RUN mkdir -p \
#     ${HOME}/.config/caddy ${HOME}/.local \
#     && chmod -R a+rw ${HOME}/.config/caddy ${HOME}/.local

COPY --chown=${USER}:${USER} deployment/octane/FrankenPHP/supervisord.frankenphp.conf /etc/supervisor/conf.d/
COPY --chown=${USER}:${USER} deployment/supervisord.*.conf /etc/supervisor/conf.d/
COPY --chown=${USER}:${USER} deployment/start-container /usr/local/bin/start-container
COPY --chown=${USER}:${USER} deployment/php.ini ${PHP_INI_DIR}/conf.d/99-octane.ini

RUN composer install \
    --classmap-authoritative \
    --no-interaction \
    --no-ansi \
    --no-dev \
    && composer clear-cache \
    && php artisan storage:link

COPY --chown=${USER}:${USER} --from=server /usr/local/bin/frankenphp ./frankenphp

RUN chmod +x /usr/local/bin/start-container frankenphp

RUN cat deployment/utilities.sh >> ~/.bashrc

EXPOSE 9003
EXPOSE 443
EXPOSE 443/udp
EXPOSE 2019

ENTRYPOINT ["start-container"]

HEALTHCHECK --start-period=5s --interval=2s --timeout=5s --retries=8 CMD php artisan octane:status || exit 1
