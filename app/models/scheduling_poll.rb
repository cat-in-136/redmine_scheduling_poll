class SchedulingPoll < ActiveRecord::Base
  unloadable

  belongs_to :issue
  has_many :scheduling_poll_item, :dependent => :destroy
  accepts_nested_attributes_for :scheduling_poll_item, :allow_destroy => true

  def votes_by_user(user)
    self.scheduling_poll_item.map { |i| i.votes_by_user(user) }.flatten
  end
  def users
    self.scheduling_poll_item.map { |i| i.users }.flatten.uniq { |u| u.id }
  end

end
