require 'redmine'
require_dependency 'redmine_scheduling_poll/hooks'
require_dependency 'redmine_scheduling_poll/macros'

Redmine::Plugin.register :redmine_scheduling_poll do
  name 'Scheduling Poll plugin'
  author '@cat_in_136'
  description 'provide simple polls to scheduling appointments'
  version '0.0.0'
  url 'https://github.com/cat-in-136/redmine_scheduling_poll'
  author_url 'https://github.com/cat-in-136/'

  project_module :scheduling_polls do
    permission :view_schduling_polls, :polls => [:show]
    permission :vote_schduling_polls, :polls => [:new, :create, :edit, :update, :vote]
  end
end
