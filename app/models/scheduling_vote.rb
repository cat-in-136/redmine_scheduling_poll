class SchedulingVote < ActiveRecord::Base
  unloadable

  belongs_to :user
  belongs_to :scheduling_poll_item
end
