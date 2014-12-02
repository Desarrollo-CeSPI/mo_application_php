name             'mo_application_php'
maintainer       'Christian A. Rodriguez & Leandro Di Tommaso'
maintainer_email 'chrodriguez@gmail.com leandro.ditommaso@mikroways.net'
license          'All rights reserved'
description      'Installs/Configures mo_application_php'
long_description 'Installs/Configures mo_application_php'
version          '0.1.25'

depends         'mo_application',     "~> 0.1.1"
depends         'php5-fpm',           "~> 0.3.1"
depends         'wkhtmltox',          "~> 0.1.0"
depends         'sudo',               "~> 2.7.1"

supports        "ubuntu", "<= 12.04"
