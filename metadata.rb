name             'mo_application_php'
maintainer       'Christian A. Rodriguez & Leandro Di Tommaso'
maintainer_email 'chrodriguez@gmail.com leandro.ditommaso@mikroways.net'
license          'All rights reserved'
description      'Installs/Configures mo_application_php'
long_description 'Installs/Configures mo_application_php'
version          '1.0.1'

depends         'mo_application',     "~> 1.0.0"
depends         'php5-fpm',           "~> 0.4.0"
depends         'wkhtmltox',          "~> 0.1.0"
depends         'sudo',               "~> 2.7.1"

supports        "ubuntu", "<= 12.04"
