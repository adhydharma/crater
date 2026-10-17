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

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql pdo_pgsql pgsql mbstring zip exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy application code into container
COPY . /var/www

# Clear pre-existing cache files
RUN rm -rf bootstrap/cache/*.php

# Install Composer dependencies
RUN composer install --no-dev --optimize-autoloader --no-scripts
RUN composer dump-autoload --no-scripts --optimize

# Create system user and fix permissions
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user && \
    chown -R $user:www-data /var/www

# Buat file .env kosong, berikan izin tulis, dan atur folder permission (sebagai root)
RUN touch /var/www/.env && \
    chown $user:www-data /var/www/.env && \
    chmod 666 /var/www/.env && \
    chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Expose port 5000 untuk Miget
EXPOSE 5000

USER $user

# Jalankan server Laravel pada port 5000
# Jalankan key:generate, migrasi database, lalu jalankan server Laravel
CMD ["sh", "-c", "php artisan key:generate --force && php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=5000"]
