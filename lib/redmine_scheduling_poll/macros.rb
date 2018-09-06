# frozen_string_literal: true

Redmine::WikiFormatting::Macros.register do
  desc "Inserts a link to a scheduling poll (/scheduling_polls/:id/show). Example:\n\n" +
      "{{scheduling_poll(1)}} -- link to /scheduling_polls/1/show"
  macro :scheduling_poll do |obj, args|
    id = args.first
    scheduling_poll = SchedulingPoll.find(id)
    link_to( l(:label_link_scheduling_poll, num: id), scheduling_poll_url(scheduling_poll))
  end
end
