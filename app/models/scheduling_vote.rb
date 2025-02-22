# frozen_string_literal: true
class SchedulingVote < (defined?(ApplicationRecord) == 'constant' ? ApplicationRecord : ActiveRecord::Base)
  unloadable if respond_to?(:unloadable)

  belongs_to :user
  belongs_to :scheduling_poll_item

  delegate :project, :to => :scheduling_poll_item
  delegate :scheduling_poll, :to => :scheduling_poll_item

  acts_as_event :title => Proc.new { |o| "#{l(:label_scheduling_poll)}: #{o.scheduling_poll_item.scheduling_poll.issue}" },
                :description => Proc.new { |o| "#{l(:label_vote_on_scheduling_poll)}: #{o.scheduling_poll_item.text}: #{SchedulingPollsController.helpers.scheduling_vote_value(o.value)}" },
                :datetime => Proc.new { |o| o.updated_at || o.created_at },
                :author => Proc.new { |o| o.user },
                :group => :scheduling_poll,
                :url => Proc.new { |o| {:controller => 'scheduling_polls', :action => 'show', :id => o.scheduling_poll_item.scheduling_poll.id } }

  acts_as_activity_provider :type => "scheduling_vote",
                            :timestamp => "COALESCE(#{table_name}.updated_at, #{table_name}.created_at)",
                            :permission => :view_schduling_polls,
                            :author_key => :user_id,
                            :scope =>joins(:scheduling_poll_item => {:scheduling_poll => {:issue => :project}})

  validates :user, :presence => true
  validates :scheduling_poll_item, :presence => true
  validates :value, :numericality => { :greater_than => 0 }, :presence => true
end
