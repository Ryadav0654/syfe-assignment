FROM wordpress:6.4-php8.1-fpm

RUN apt-get update && apt-get install -y less unzip git && rm -rf /var/lib/apt/lists/*

# Optional: install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

RUN chown -R www-data:www-data /var/www/html

EXPOSE 9000
CMD ["php-fpm"]
