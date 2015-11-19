class SchedulingPoll < ActiveRecord::Base
  unloadable

  belongs_to :issue
  has_many :scheduling_poll_items, :dependent => :destroy
  accepts_nested_attributes_for :scheduling_poll_items, :reject_if => :reject_scheduling_poll_items, :allow_destroy => true

  validates :issue, :presence => true

  def votes_by_user(user)
    self.scheduling_poll_items.map { |i| i.vote_by_user(user) }.reject { |v| v.nil? }
  end
  def users
    self.scheduling_poll_items.map { |i| i.users }.flatten.uniq { |u| u.id }
  end

  private
  def reject_scheduling_poll_items(attributed)
    attributed['text'].blank?
  end

end
