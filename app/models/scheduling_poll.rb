class SchedulingPoll < ActiveRecord::Base
  unloadable

  belongs_to :issue
  has_many :scheduling_poll_items, :dependent => :destroy
  accepts_nested_attributes_for :scheduling_poll_items, :reject_if => :reject_scheduling_poll_items, :allow_destroy => true
  has_many :votes, :through => :scheduling_poll_items, :source => :scheduling_votes
  has_many :users, lambda { order(:id).distinct }, :through => :scheduling_poll_items

  validates :issue, :presence => true

  def votes_by_user(user)
    self.votes.where(:user => user)
  end

  private
  def reject_scheduling_poll_items(attributed)
    attributed['text'].blank?
  end

end
