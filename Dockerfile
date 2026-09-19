# Usa un'immagine ufficiale di PHP con Apache (ottima per le API Symfony)
FROM php:8.3-apache

# Installa le dipendenze di sistema necessarie
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql zip

# Abilita il modulo rewrite di Apache (fondamentale per le rotte di Symfony)
RUN a2enmod rewrite

# Installa Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1

# Cloud Run ascolta di default sulla porta 8080
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
RUN sed -i 's/:80/:8080/' /etc/apache2/sites-available/000-default.conf

# Diciamo ad Apache che la cartella pubblica è /public (standard Symfony)
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Copia i file del tuo progetto dentro il container
WORKDIR /var/www/html
COPY . .

# Installa le dipendenze di Symfony (senza i pacchetti dev)
RUN composer install --no-dev --optimize-autoloader

# Pulisci la cache e imposta i permessi corretti
RUN mkdir -p var/cache var/log
RUN php bin/console cache:clear --env=prod
RUN chown -R www-data:www-data /var/www/html/var
