#!/bin/bash
# inspired by https://gist.github.com/pinzolo/7599006

#REDMINE_VERSION="2.4.0"
PLUGIN_NAME=redmine_scheduling_poll

# Shelve the plugin files to a temporary directory
cp -pr . /tmp/${PLUGIN_NAME}

# Get & deploy Redmine
wget http://www.redmine.org/releases/redmine-${REDMINE_VERSION}.tar.gz
tar zxf redmine-${REDMINE_VERSION}.tar.gz
mv redmine-${REDMINE_VERSION} redmine

# Copy the plugin files to plugin directory
cp -pr /tmp/${PLUGIN_NAME} redmine/plugins/${PLUGIN_NAME}

# Create necessary files
cat > redmine/config/database.yml <<_EOS_
test:
  adapter: sqlite3
  database: db/redmine_test.db
_EOS_
