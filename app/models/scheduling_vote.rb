class SchedulingVote < ActiveRecord::Base
  unloadable

  belongs_to :user
  belongs_to :scheduling_poll_item

  validates :user, :presence => true
  validates :scheduling_poll_item, :presence => true
  validates :value, :numericality => { :greater_than => 0 }, :presence => true
end
