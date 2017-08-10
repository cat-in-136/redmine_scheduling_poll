require 'redmine'
require_dependency 'redmine_scheduling_poll/hooks'
require_dependency 'redmine_scheduling_poll/macros'

Redmine::Plugin.register :redmine_scheduling_poll do
  name 'Scheduling Poll plugin'
  author '@cat_in_136'
  description 'provide simple polls to scheduling appointments'
  version '2.2.0'
  url 'https://github.com/cat-in-136/redmine_scheduling_poll'
  author_url 'https://github.com/cat-in-136/'

  project_module :scheduling_polls do
    permission :view_schduling_polls, :polls => [:show, :show_by_issue]
    permission :vote_schduling_polls, :polls => [:new, :create, :edit, :update, :vote]
  end

  settings :default => {
    'scheduling_vote_value_5' => '',
    'scheduling_vote_value_4' => '',
    'scheduling_vote_value_3' => 'OK',
    'scheduling_vote_value_2' => 'maybe',
    'scheduling_vote_value_1' => 'NG',
    'scheduling_poll_item_date_format' => 'yy-mm-dd',
  }, :partial => 'settings/scheduling_poll_settings'
end
