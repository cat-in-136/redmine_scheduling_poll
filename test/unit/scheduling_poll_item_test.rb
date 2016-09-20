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

  test "sorted shall be sorted in ascending order of position" do
    scheduling_poll_items = SchedulingPollItem.where(:scheduling_poll_id => 1).sorted
    assert_equal 3, scheduling_poll_items.length
    assert_equal SchedulingPollItem.find(1), scheduling_poll_items[0]
    assert_equal SchedulingPollItem.find(2), scheduling_poll_items[1]
    assert_equal SchedulingPollItem.find(3), scheduling_poll_items[2]

    scheduling_poll_items = SchedulingPollItem.where(:scheduling_poll_id => 2).sorted
    assert_equal 3, scheduling_poll_items.length
    assert_equal SchedulingPollItem.find(6), scheduling_poll_items[0]
    assert_equal SchedulingPollItem.find(5), scheduling_poll_items[1]
    assert_equal SchedulingPollItem.find(4), scheduling_poll_items[2]
  end

  test "vote_by_user shall return the vote which the user votes" do
    scheduling_poll_item = SchedulingPollItem.find(1)
    user = User.find(1)
    assert_equal SchedulingVote.find(1), scheduling_poll_item.vote_by_user(user)

    user = User.find(3)
    assert_equal SchedulingVote.find(7), scheduling_poll_item.vote_by_user(user)
  end

  test "vote_value_by_user shall return the vote value which the user votes" do
    scheduling_poll_item = SchedulingPollItem.find(1)
    user = User.find(1)
    assert_equal SchedulingVote.find(1).value, scheduling_poll_item.vote_value_by_user(user)

    user = User.find(3)
    assert_equal SchedulingVote.find(7).value, scheduling_poll_item.vote_value_by_user(user)

    user = User.find(5)
    assert_equal 0, scheduling_poll_item.vote_value_by_user(user)
  end

  test "users shall return all the users who vote the item" do
    user_id = User.arel_table[:id]

    scheduling_poll_item = SchedulingPollItem.find(1)
    users = User.where(user_id.eq(1).or(user_id.eq(2).or(user_id.eq(3))))
    assert_equal users.sort, scheduling_poll_item.users.sort

    scheduling_poll_item = SchedulingPollItem.find(2)
    users = User.where(user_id.eq(1).or(user_id.eq(2)))
    assert_equal users.sort, scheduling_poll_item.users.sort
  end

  test "vote with non-zero value shall add the vote or update" do
    scheduling_poll_item = SchedulingPollItem.new
    scheduling_poll_item.text = "__test_item__"
    scheduling_poll_item.scheduling_poll = SchedulingPoll.first
    assert scheduling_poll_item.save

    user = User.find(5)

    assert_empty SchedulingVote.where(:user => user)
    scheduling_poll_item.vote(user, 1)
    assert_equal 1, SchedulingVote.where(:user => user, :scheduling_poll_item => scheduling_poll_item).length
    assert_equal 1, SchedulingVote.find_by(:user => user, :scheduling_poll_item => scheduling_poll_item).value

    scheduling_poll_item.vote(user, 2)
    assert_equal 1, SchedulingVote.where(:user => user, :scheduling_poll_item => scheduling_poll_item).length
    assert_equal 2, SchedulingVote.find_by(:user => user, :scheduling_poll_item => scheduling_poll_item).value

    assert scheduling_poll_item.destroy
  end

  test "vote with zero value shall remove the vote" do
    scheduling_poll_item = SchedulingPollItem.new
    scheduling_poll_item.text = "__test_item__"
    scheduling_poll_item.scheduling_poll = SchedulingPoll.first
    assert scheduling_poll_item.save

    user = User.find(5)

    assert_empty SchedulingVote.where(:user => user)
    scheduling_poll_item.vote(user, 0)
    assert_equal 0, SchedulingVote.where(:user => user, :scheduling_poll_item => scheduling_poll_item).length

    scheduling_poll_item.vote(user, 1)
    assert_equal 1, SchedulingVote.where(:user => user, :scheduling_poll_item => scheduling_poll_item).length

    scheduling_poll_item.vote(user, 0)
    assert_equal 0, SchedulingVote.where(:user => user, :scheduling_poll_item => scheduling_poll_item).length

    assert scheduling_poll_item.destroy
  end
end
