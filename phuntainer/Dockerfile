FROM php:7.3-apache
LABEL maintainer="Jake Staehle <jacob@staehle.us>"

ENV DEBIAN_FRONTEND=noninteractive

# General apt requirements
RUN apt-get -q update \
	&& apt-get install -yq \
		ca-certificates \
		curl \
		ftp \
		git \
		imagemagick \
		libcurl4-openssl-dev \
		libfreetype6-dev \
		libjpeg-dev \
		libjpeg62-turbo-dev \
		libmcrypt-dev \
		libpng-dev \
		libssl-dev \
		libzip-dev \
		mercurial \
		python-pygments \
		sendmail \
		subversion \
		unzip \
		wget \
		zip \
	&& rm -rf /var/lib/apt/lists/*

RUN echo "no" | pecl install APCu \
	&& docker-php-ext-enable apcu

# Install pdo_mysql
RUN docker-php-ext-install mysqli pdo_mysql

# Install phabricator dependencies
RUN docker-php-ext-configure gd \
		--with-freetype-dir=/usr/include/ \
		--with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install -j$(nproc) \
		curl \
		ftp \
		gd \
		iconv \
		json \
		mbstring \
		opcache \
		pcntl \
		sockets \
		zip

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
# RUN mkdir -p /usr/local/etc/php/conf.d \
#     && { \
#         echo 'opcache.memory_consumption=128'; \
#         echo 'opcache.interned_strings_buffer=8'; \
#         echo 'opcache.max_accelerated_files=4000'; \
#         echo 'opcache.revalidate_freq=60'; \
#         echo 'opcache.fast_shutdown=1'; \
#         # From Phabricator
#         echo 'opcache.validate_timestamps=0'; \
#     } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Set the default timezone.
# RUN { \
#         echo 'date.timezone="UTC"'; \
#     } > /usr/local/etc/php/conf.d/timezone.ini

# File Uploads
# RUN { \
#         echo 'post_max_size=32M'; \
#         echo 'upload_max_filesize=32M'; \
#     } > /usr/local/etc/php/conf.d/uploads.ini

# Install apache mod rewrite
RUN a2enmod rewrite

# Phab source, 'stable' branch for all
RUN mkdir /phab \
	&& git clone --branch stable https://github.com/phacility/libphutil.git /phab/libphutil \
	&& git clone --branch stable https://github.com/phacility/arcanist.git /phab/arcanist \
	&& git clone --branch stable https://github.com/phacility/phabricator.git /phab/phabricator

# Add Phabricator to Apache
RUN a2dissite 000-default
COPY files/site.conf /etc/apache2/sites-available/phab.conf
RUN a2ensite phab

COPY files/local.json /phab/phabricator/conf/local/local.default

ENV PATH "$PATH:/phab/phabricator/bin"

EXPOSE 22 80 443

COPY files/phun.sh /phab/phabricator/phun.sh

WORKDIR /phab/phabricator
#ENTRYPOINT /phab/phabricator/phun.sh
CMD /phab/phabricator/phun.sh
