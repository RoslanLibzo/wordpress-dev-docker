# syntax=docker/dockerfile:1
# Use an official PHP image as the base
FROM php:8.1-fpm

# Set working directory
WORKDIR /var/www/html

# Install system dependencies, Node.js, Yarn, PHP extensions, and WP-CLI in one RUN command
RUN apt-get update && apt-get install -y nginx \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    curl \
    mariadb-client \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn \
    && yarn global add @roots/bud \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd mysqli \
    && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create a non-root user and group with a specific UID and GID (optional)
RUN groupadd -g 1000 appuser && useradd -u 1000 -g appuser -m appuser

# Copy the application code as the non-root user
COPY --chown=appuser:appuser . .

# Use Composer cache
# RUN mkdir -p /root/.composer && chown -R appuser:appuser /root/.composer

# Switch back to root user for setting permissions and installing dependencies
# USER root
# RUN chmod -R 755 /var/www/html \
# composer install --no-interaction --prefer-dist --optimize-autoloader

# Change ownership of necessary directories to non-root user (if needed)
# RUN chown -R appuser:appuser /var/www/html

# Expose port 9000 and start php-fpm server
EXPOSE 9000
USER appuser
CMD ["php-fpm"]