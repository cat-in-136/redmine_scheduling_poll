class SchedulingVote < ActiveRecord::Base
  unloadable

  belongs_to :user
  belongs_to :scheduling_vote_item
end
