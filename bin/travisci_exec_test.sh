#!/bin/bash
# inspired by https://gist.github.com/pinzolo/7599006

export REDMINE_LANG=en
export RAILS_ENV=test

#REDMINE_VERSION="2.4.0"
PLUGIN_NAME=redmine_scheduling_poll

cd redmine-${REDMINE_VERSION}

bundle install --path=vendor/bundle

# Initialize redmine
bundle exec rake generate_secret_token
bundle exec rake db:migrate
bundle exec rake redmine:load_default_data

# Copy assets & execute plugin's migration
bundle exec rake redmine:plugins NAME=${PLUGIN_NAME}

# Execute test
bundle exec rake redmine:plugins:test NAME=${PLUGIN_NAME}
