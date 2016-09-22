class SchedulingPollItem < ActiveRecord::Base
  unloadable

  belongs_to :scheduling_poll
  has_many :scheduling_votes, :dependent => :destroy
  has_many :users, lambda { order(:id).distinct }, :through => :scheduling_votes

  scope :sorted, lambda { order(:position => :asc) }

  validates :scheduling_poll, :presence => true
  validates :text, :presence => true, :allow_blank => false

  def vote_by_user(user)
    self.scheduling_votes.find_by(:user => user)
  end
  def vote_value_by_user(user)
    v = self.vote_by_user(user)
    (v.nil?)? 0 : v.value
  end

  def vote(user, value=0)
    value = value.to_i
    v = self.vote_by_user(user)
    unless value == 0
      if v.nil?
        v = self.scheduling_votes.create(:user => user, :value => value, :create_at => Time.now)
      else
        v.update(:value => value, :modify_at => Time.now)
      end
    else # remove vote
      v.destroy unless v.nil?
    end
    v
  end
end
