require 'redmine'
require File.expand_path('../lib/redmine_scheduling_poll/hooks', __FILE__)

Redmine::Plugin.register :redmine_scheduling_poll do
  requires_redmine :version_or_higher => '4.0.0'

  name 'Scheduling Poll plugin'
  author '@cat_in_136'
  description 'provide simple polls to scheduling appointments'
  version '4.1.1'
  url 'https://github.com/cat-in-136/redmine_scheduling_poll'
  author_url 'https://github.com/cat-in-136/'

  project_module :scheduling_polls do
    permission :view_schduling_polls, :polls => [:show, :show_by_issue]
    permission :vote_schduling_polls, :polls => [:new, :create, :edit, :update, :vote]
  end
  Redmine::Activity.map do |activity|
    activity.register(:scheduling_poll)
    activity.register(:scheduling_poll_item)
    activity.register(:scheduling_vote)
  end

  settings :default => {
    'scheduling_vote_value_5' => '',
    'scheduling_vote_value_4' => '',
    'scheduling_vote_value_3' => 'OK',
    'scheduling_vote_value_2' => 'maybe',
    'scheduling_vote_value_1' => 'NG',
    'scheduling_poll_item_date_format' => 'yy-mm-dd',
  }, :partial => 'settings/scheduling_poll_settings'

  Redmine::WikiFormatting::Macros.register do
    desc "Inserts a link to a scheduling poll (/scheduling_polls/:id/show). Example:\n\n" +
        "{{scheduling_poll(1)}} -- link to /scheduling_polls/1/show"
    macro :scheduling_poll do |obj, args|
      id = args.first
      scheduling_poll = SchedulingPoll.find(id)
      link_to( l(:label_link_scheduling_poll, num: id), scheduling_poll_url(scheduling_poll))
    end
  end
end
