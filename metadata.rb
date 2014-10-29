name             'cespi_application_php'
maintainer       'Christian A. Rodriguez & Leandro Di Tommaso'
maintainer_email 'car@cespi.unlp.edu.ar lditommaso@cespi.unlp.edu.ar'
license          'All rights reserved'
description      'Installs/Configures cespi_application_php'
long_description 'Installs/Configures cespi_application_php'
version          '0.1.2'

depends         'cespi_application',  '~> 0.1.1'
depends         'hostsfile',          '= 2.4.5'
depends         'php5-fpm',           "~> 0.2.1"
depends         'nginx',              "~> 2.7.4"
depends         'nginx_conf',         "~> 0.2.4"
depends         'wkhtmltox',          "~> 0.1.0"
depends         'chef-sugar'
depends         'chef-msttcorefonts', "~> 0.9.0"
