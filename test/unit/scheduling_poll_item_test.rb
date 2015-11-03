require File.expand_path('../../test_helper', __FILE__)

class SchedulingPollItemTest < ActiveSupport::TestCase
  fixtures :issues, :users, :scheduling_polls, :scheduling_poll_items, :scheduling_votes

  test "shall not save scheduling poll item without scheduling poll" do
    scheduling_poll_item = SchedulingPollItem.new
    scheduling_poll_item.text = "dummy"
    assert_not scheduling_poll_item.save

    scheduling_poll_item.scheduling_poll = SchedulingPoll.first
    assert scheduling_poll_item.save
    assert scheduling_poll_item.destroy
  end

  test "shall not save scheduling poll item without text" do
    scheduling_poll_item = SchedulingPollItem.new
    scheduling_poll_item.scheduling_poll = SchedulingPoll.first
    assert_not scheduling_poll_item.save

    scheduling_poll_item.text = '' # empty text
    assert_not scheduling_poll_item.save

    scheduling_poll_item.text = ' ' # white space
    assert_not scheduling_poll_item.save

    scheduling_poll_item.text = 'a'
    assert scheduling_poll_item.save
    assert scheduling_poll_item.destroy
  end
end
