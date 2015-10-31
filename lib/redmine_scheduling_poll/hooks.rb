module RedmineSchedulingPoll
  class Hooks < Redmine::Hook::ViewListener

    render_on :view_issues_show_description_bottom,
              :partial => 'hooks/redmine_scheduling_poll/view_issues_show_description_bottom'
  end
end
