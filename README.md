GRUB2 Config Files Api Gem
=====================
[![Code Climate](https://codeclimate.com/github/config-files-api/config_files_api_grub2/badges/gpa.svg)](https://codeclimate.com/github/config-files-api/config_files_api_grub2)
[![Coverage Status](https://coveralls.io/repos/config-files-api/config_files_api_grub2/badge.svg?branch=master&service=github)](https://coveralls.io/github/config-files-api/config_files_api_grub2?branch=master)
[![Build Status](https://travis-ci.org/config-files-api/config_files_api_grub2.svg?branch=master)](https://travis-ci.org/config-files-api/config_files_api_grub2)

Ruby gem providing a plugin for easy access and modify of
configuration files for GRUB2. It uses [config_files_api framework](https://github.com/config-files-api/config_files_api).

For examples of usage see directory examples and rspec testsuite.

How to Release Gem to Build Service
----------------------------------

1. push new gem to rubygems.org
2. go to build service repo checkout
3. fetch new gem and remove old one
4. copy CHANGELOG to .changes file
5. use gem2rpm to generate new spec file
6. submit changes
