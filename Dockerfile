# Use the official PHP image.
# https://hub.docker.com/_/php
FROM php:7.4-apache

# Etiqueta de información del creador
LABEL maintainer="Eduardo Rosales <eduardorosales720@gmail.com>"

# Actualiza el índice de paquetes e instala dependencias
RUN apt-get update \
    && apt-get install -y \
        libzip-dev \
        libjpeg-dev \
        libpng-dev \
        default-mysql-client \
        wget \
        git \
        zsh \
        nano \
    && rm -rf /var/lib/apt/lists/*

# Habilita el módulo mod_rewrite de Apache
RUN a2enmod rewrite

# Configure PHP for Cloud Run.
# Precompile PHP code with opcache.
RUN docker-php-ext-install -j "$(nproc)" opcache mysqli pdo pdo_mysql zip gd exif
RUN set -ex; \
  { \
    echo "; Cloud Run enforces memory & timeouts"; \
    echo "memory_limit = -1"; \
    echo "max_execution_time = 0"; \
    echo "; File upload at Cloud Run network limit"; \
    echo "upload_max_filesize = 32M"; \
    echo "post_max_size = 32M"; \
    echo "; Configure Opcache for Containers"; \
    echo "opcache.enable = On"; \
    echo "opcache.validate_timestamps = Off"; \
    echo "; Configure Opcache Memory (Application-specific)"; \
    echo "opcache.memory_consumption = 32"; \
  } > "$PHP_INI_DIR/conf.d/cloud-run.ini"

# Copy in custom code from the host machine.
WORKDIR /var/www/html
COPY ./ ./

# Use the PORT environment variable in Apache configuration files.
# https://cloud.google.com/run/docs/reference/container-contract#port
# Definir el puerto por defecto como 8080
ENV PORT=8080
RUN sed -i "s/80/\${PORT}/g" /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# Configure PHP for development.
# Switch to the production php.ini for production operations.
# RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
# https://github.com/docker-library/docs/blob/master/php/README.md#configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
