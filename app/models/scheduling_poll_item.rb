class SchedulingPollItem < ActiveRecord::Base
  unloadable

  belongs_to :scheduling_poll
  has_many :scheduling_vote, :dependent => :destroy

  def vote_by_user(user)
    self.scheduling_vote.where(:user => user).first
  end
  def users
    self.scheduling_vote.map {|v| v.user }
  end

  def vote(user, value=5)
    v = self.vote_by_user(user)
    if v.nil?
      v = self.scheduling_vote.create(:user => user, :value => value, :create_at => Time.now)
    else
      v.update(:value => value, :modify_at => Time.now)
    end
    v
  end
end
