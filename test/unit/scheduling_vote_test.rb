require File.expand_path('../../test_helper', __FILE__)

class SchedulingVoteTest < ActiveSupport::TestCase
  fixtures :issues, :users, :scheduling_polls, :scheduling_poll_items, :scheduling_votes

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
end
