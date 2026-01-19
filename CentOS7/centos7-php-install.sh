#!/bin/bash

read -p "インストールするPHPバージョンを入力 (例: 8.3なら83): " phpver

echo "php${phpver}でよろしいですか？(y/n)"
read -r confirm
if [[ "$confirm" != "y" ]]; then
    echo "中止しました。"
    exit 1
fi

yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum -y install yum-utils
yum -y update

yum-config-manager --disable 'remi-php*'
yum-config-manager --enable remi-php${phpver}

yum -y install php${phpver} php${phpver}-php-bcmath php${phpver}-php-common php${phpver}-php-devel php${phpver}-php-fpm php${phpver}-php-gd php${phpver}-php-mbstring php${phpver}-php-pdo php${phpver}-php-pear php${phpver}-php-xml php${phpver}-php-pecl-zip php${phpver}-php-intl php${phpver}-php-sodium php${phpver}-php-pecl-apcu

yum-config-manager --disable 'remi-php*'

php${phpver} -v
