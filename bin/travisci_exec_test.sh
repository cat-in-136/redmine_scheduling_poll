#!/bin/bash
# inspired by https://gist.github.com/pinzolo/7599006

export REDMINE_LANG=en
export RAILS_ENV=test

#REDMINE_VERSION="2.4.0"
PLUGIN_NAME=redmine_scheduling_poll

cd redmine-${REDMINE_VERSION}

# Execute test
bundle exec rake redmine:plugins:test NAME=${PLUGIN_NAME}

# Execute UI test
phantomjs --webdriver 0.0.0.0:4444 >> phantomjs.log &
bundle exec rake redmine:plugins:test:ui NAME=${PLUGIN_NAME}
killall phantomjs
cat phantomjs.log
