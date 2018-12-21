# frozen_string_literal: true
require File.expand_path('../../test_helper', __FILE__)

class SchedulingVoteTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :roles, :users
  ActiveRecord::FixtureSet.create_fixtures(File.join(File.dirname(__FILE__), '../fixtures'),
                                           [:scheduling_polls, :scheduling_poll_items, :scheduling_votes])

  test "shall not save scheduling vote without user" do
    scheduling_vote = SchedulingVote.new
    scheduling_vote.scheduling_poll_item = SchedulingPollItem.first
    scheduling_vote.value = 1
    assert_not scheduling_vote.save

    scheduling_vote.user = User.first
    assert scheduling_vote.save
    assert scheduling_vote.destroy
  end

  test "shall not save scheduling vote without scheduling poll item" do
    scheduling_vote = SchedulingVote.new
    scheduling_vote.user = User.first
    scheduling_vote.value = 1
    assert_not scheduling_vote.save

    scheduling_vote.scheduling_poll_item = SchedulingPollItem.first
    assert scheduling_vote.save
    assert scheduling_vote.destroy
  end

  test "shall not save scheduling vote without value" do
    scheduling_vote = SchedulingVote.new
    scheduling_vote.user = User.first
    scheduling_vote.scheduling_poll_item = SchedulingPollItem.first
    assert_not scheduling_vote.save

    scheduling_vote.value = 1
    assert scheduling_vote.save
    assert scheduling_vote.destroy
  end

  test "vote value shall be larger than zero" do
    scheduling_vote = SchedulingVote.new
    scheduling_vote.user = User.first
    scheduling_vote.scheduling_poll_item = SchedulingPollItem.first

    scheduling_vote.value = -1
    assert_not scheduling_vote.save
    scheduling_vote.value = 0
    assert_not scheduling_vote.save
    scheduling_vote.value = 1
    assert scheduling_vote.save

    assert scheduling_vote.destroy
  end

  test "activity fetcher shall be return based on :created_at" do
    Project.find(1).enable_module! :scheduling_polls
    Role.all.each do |role|
      role.add_permission! :view_schduling_polls
    end
    fetcher = Redmine::Activity::Fetcher.new(User.find(2))
    fetcher.scope = %w[scheduling_vote]

    expected = SchedulingVote.all.sort {|a,b| b.created_at <=> a.created_at }
    assert_equal expected, fetcher.events(1.day.ago, Date.today + 1)
  end
end
