FROM php:8.1-fpm

ARG user=craterapp
ARG uid=1000

# Install system dependencies & PostgreSQL development libraries (libpq-dev)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libmagickwand-dev \
    libpq-dev \
    mariadb-client

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install PHP extensions (Added pgsql and pdo_pgsql)
RUN docker-php-ext-install pdo_mysql pdo_pgsql pgsql mbstring zip exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy application code into container
COPY . /var/www

# Clear any pre-existing cache files from local development
RUN rm -rf bootstrap/cache/*.php

# Install Composer dependencies without running scripts
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Dump autoload explicitly without scripts to prevent package:discover from running
RUN composer dump-autoload --no-scripts --optimize

# Create system user and fix permissions
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user && \
    chown -R $user:www-data /var/www

USER $user
