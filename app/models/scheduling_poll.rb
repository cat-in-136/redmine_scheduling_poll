class SchedulingPoll < ActiveRecord::Base
  unloadable

  belongs_to :issue
  has_many :scheduling_poll_items, :dependent => :destroy
  accepts_nested_attributes_for :scheduling_poll_items, :reject_if => :reject_scheduling_poll_items, :allow_destroy => true

  validates :issue, :presence => true

  def votes
    SchedulingVote.where(:scheduling_poll_item => self.scheduling_poll_items)
  end
  def votes_by_user(user)
    self.votes.where(:user => user)
  end
  def users
    User.where(:id => self.votes.pluck(:user_id))
  end

  private
  def reject_scheduling_poll_items(attributed)
    attributed['text'].blank?
  end

end
