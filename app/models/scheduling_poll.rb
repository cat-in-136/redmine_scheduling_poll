# frozen_string_literal: true
class SchedulingPoll < ActiveRecord::Base
  unloadable

  belongs_to :issue
  has_many :scheduling_poll_items, :dependent => :destroy
  accepts_nested_attributes_for :scheduling_poll_items, :reject_if => :reject_scheduling_poll_items, :allow_destroy => true
  has_many :votes, :through => :scheduling_poll_items, :source => :scheduling_votes
  has_many :users, lambda { order(:id).distinct }, :through => :scheduling_poll_items

  delegate :project, :to => :issue

  validates :issue, :presence => true

  acts_as_event :title => Proc.new { |o| "#{l(:label_scheduling_poll)}: #{o.issue}" },
                :description => nil,
                :datetime => :created_at,
                :author => nil,
                :group => :issue,
                :url => Proc.new { |o| {:controller => 'scheduling_polls', :action => 'show', :id => o.id } }

  acts_as_activity_provider :type => "scheduling_poll",
                            :timestamp => :created_at,
                            :permission => :view_schduling_polls,
                            :author_key => nil,
                            :scope =>joins(:issue => :project)

  def votes_by_user(user)
    self.votes.where(:user => user)
  end

  private
  def reject_scheduling_poll_items(attributed)
    attributed['text'].blank?
  end

end
