require File.expand_path('../../test_helper', __FILE__)

class SchedulingPollTest < ActiveSupport::TestCase
  fixtures :issues, :users, :scheduling_polls, :scheduling_poll_items, :scheduling_votes

  test "shall not save scheduling poll without issue" do
    scheduling_poll = SchedulingPoll.new
    assert_not scheduling_poll.save

    scheduling_poll.issue = Issue.first
    assert scheduling_poll.save
    assert scheduling_poll.destroy
  end
end
