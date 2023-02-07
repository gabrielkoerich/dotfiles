#!/usr/bin/env bash

brew install php
brew install brew-php-switcher

#brew tap mongodb/brew
#brew install
#brew install mongodb-community

# PHP Configs
# cp ./config/php-memory-limits.ini /usr/local/etc/php/7.4/conf.d/php-memory-limits.ini
# cp ./config/php-memory-limits.ini /opt/homebrew/etc/php/7.4/conf.d/php-memory-limits.ini
# cp ./config/psysh.php ~/.config/psysh/config.php

# Fix pecl builds on mac m1
# brew install pcre2
# ln -s /opt/homebrew/Cellar/pcre2/10.37/include/pcre2.h /opt/homebrew/Cellar/php/"$(php -v | grep ^PHP | cut -d' ' -f2)"/include/php/ext/pcre/pcre2.h
#brew install icu4c

# Install Xdebug + Mongo via pecl
# pecl install xdebug
# pecl install mongodb
# pecl install redis

# brew tap kabel/php-ext
# brew install php-imap
#
# Install composer
curl -sS https://getcomposer.org/installer | php

mkdir -p /usr/local/bin

sudo mv composer.phar /usr/local/bin/composer

composer global require laravel/valet
composer global require laravel/installer
composer global require phpunit/phpunit
composer global require friendsofphp/php-cs-fixer

~/.composer/vendor/bin/valet use php
~/.composer/vendor/bin/valet install

# Park valet in ~/Projects
mkdir -p ~/Projects && cd ~/Projects
~/.composer/vendor/bin/valet park
