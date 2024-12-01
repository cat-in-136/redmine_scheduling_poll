# frozen_string_literal: true
class SchedulingPollItem < (defined?(ApplicationRecord) == 'constant' ? ApplicationRecord : ActiveRecord::Base)
  unloadable if respond_to?(:unloadable)

  belongs_to :scheduling_poll
  has_many :scheduling_votes, :dependent => :destroy
  has_many :users, lambda { order(:id).distinct }, :through => :scheduling_votes

  scope :sorted, lambda { order(:position => :asc) }

  acts_as_event :title => Proc.new { |o| "#{l(:label_scheduling_poll)}: #{o.scheduling_poll.issue}" },
                :description => Proc.new { |o| "#{l(:label_scheduling_poll_item)}: #{o.text}" },
                :datetime => Proc.new { |o| o.updated_at || o.created_at },
                :author => nil,
                :group => :scheduling_poll,
                :url => Proc.new { |o| {:controller => 'scheduling_polls', :action => 'show', :id => o.scheduling_poll.id } }

  acts_as_activity_provider :type => "scheduling_poll_item",
                            :timestamp => "COALESCE(#{table_name}.updated_at, #{table_name}.created_at)",
                            :permission => :view_schduling_polls,
                            :author_key => nil,
                            :scope =>where("COALESCE(#{table_name}.updated_at, #{table_name}.created_at) IS NOT NULL").joins(:scheduling_poll => {:issue => :project})

  validates :scheduling_poll, :presence => true
  validates :text, :presence => true, :allow_blank => false

  delegate :project, :to => :scheduling_poll

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
        v = self.scheduling_votes.create(:user => user, :value => value)
      else
        v.update(:value => value)
      end
    else # remove vote
      v.destroy unless v.nil?
    end
    v
  end
end
