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
		iputils-ping \
		libcurl4-openssl-dev \
		libfreetype6-dev \
		libjpeg-dev \
		libjpeg62-turbo-dev \
		libmcrypt-dev \
		libpng-dev \
		libssl-dev \
		libzip-dev \
		mercurial \
		openssh-server \
		python3-pygments \
		sendmail \
		subversion \
		sudo \
		unzip \
		vim \
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

# Install PHP config files
RUN mkdir -p /usr/local/etc/php/conf.d
# https://secure.php.net/manual/en/opcache.installation.php
COPY files/opcache-recommended.ini /usr/local/etc/php/conf.d/opcache-recommended.ini
COPY files/timezone.ini /usr/local/etc/php/conf.d/timezone.ini
COPY files/uploads.ini /usr/local/etc/php/conf.d/uploads.ini
COPY files/phpexcel.ini /usr/local/etc/php/conf.d/phpexcel.ini

# Install apache mod rewrite
RUN a2enmod rewrite

# Phab source, 'stable' branch for all
RUN git clone --branch stable https://github.com/phacility/libphutil.git /libphutil
RUN git clone --branch stable https://github.com/phacility/arcanist.git /arcanist
RUN git clone --branch stable https://github.com/phacility/phabricator.git /phabricator
RUN git clone https://www.github.com/PHPOffice/PHPExcel.git /PHPExcel

# Phabricator user
# www-data is default apache user and will reuse. 'ph' is new user for both VCS and PHD
RUN mkdir -p /home/daemonuser
RUN echo "ph:x:4321:4321:DaemonUser,,,:/home/daemonuser:/bin/bash" >> /etc/passwd
RUN echo "ph:NP:18204:0:99999:7:::" >> /etc/shadow
# Phabricator group, add apache user
RUN echo "ph:!:4321:www-data" >> /etc/group
# Add sudoers definitions
RUN echo "ph ALL=(phd) SETENV: NOPASSWD: /usr/bin/git-upload-pack, /usr/bin/git-receive-pack, /usr/bin/git" >> /etc/sudoers
RUN echo "www-data ALL=(phd) SETENV: NOPASSWD: /usr/bin/git-upload-pack, /usr/lib/git-core/git-http-backend, /usr/bin/git" >> /etc/sudoers

# Add Phabricator to Apache
RUN a2dissite 000-default
COPY files/site.conf /etc/apache2/sites-available/phab.conf
RUN a2ensite phab

# Configurations
COPY files/local.json /phabricator/conf/example/local.json
COPY files/preamble.php /phabricator/conf/example/preamble.php
COPY files/sshd_config /phabricator/conf/example/sshd_config
COPY files/phabricator-ssh-hook.sh /phabricator/conf/example/phabricator-ssh-hook.sh

# Runtime
ENV PATH "$PATH:/phabricator/bin"

EXPOSE 80 443 22

COPY files/phun.sh /phabricator/phun.sh

WORKDIR /phabricator
CMD /phabricator/phun.sh
