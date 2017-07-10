
TODO:
 - [x] move code in default.pp to modules/nextcloud
 - [x] remove obsolote submodules added for profile_mysql
 - [x] required PHP modules for nextcloud
 - [x] redis instance
 - [x] collected redis
 - [x] opcache
 - [ ] fix for `PHP Warning:  Version warning: Imagick was compiled against Image Magick version 1687 but version 1688 is loaded. Imagick will run but may behave surprisingly in Unknown on line 0
` ref: https://forum.remirepo.net/viewtopic.php?id=3433
 - [x] fix for `PHP Warning:  PHP Startup: Invalid library (appears to be a Zend Extension, try loading using zend_extension=opcache.so from php.ini) in Unknown on line 0`
 - [x] fix sudo for vagrant
 - [x] configure vhost for Nextcloud
 - [x] cron
 - [x] install nextcloud using RPM:
   - using https://github.com/ledfan/rpm-nextcloud which is forked from https://github.com/mbevc1/nextcloud which is forked from https://build.opensuse.org/package/show/server:php:applications/nextcloud
   - the only change made is the addition of the "full" and "minimal" build, in the full build an apache vhost will be created in the minimal this won't be created.
   - tested the upgrade process by running `vagrant provision` from 11.0.0 to 12.0.0 to daily with a handfull apps enabled
 - [ ] idempotence of nextcloud RPM installation
