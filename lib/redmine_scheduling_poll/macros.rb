
Redmine::WikiFormatting::Macros.register do
  macro :scheduling_poll do |obj, args|
    id = args.first
    scheduling_poll = SchedulingPoll.find(id)
    link_to("{{scheduling_poll(#{id})}}", scheduling_poll_path(scheduling_poll))
  end
end
