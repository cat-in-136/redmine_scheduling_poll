# frozen_string_literal: true
require File.expand_path('../../test_helper', __FILE__)

class SchedulingPollTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :roles, :users
  ActiveRecord::FixtureSet.create_fixtures(File.join(File.dirname(__FILE__), '../fixtures'),
                                           [:scheduling_polls, :scheduling_poll_items, :scheduling_votes])

  test "shall not save scheduling poll without issue" do
    scheduling_poll = SchedulingPoll.new
    assert_not scheduling_poll.save

    scheduling_poll.issue = Issue.first
    assert scheduling_poll.save
    assert scheduling_poll.destroy
  end

  test "shall reject the scheduling poll items which has empty text" do
    scheduling_poll = SchedulingPoll.new
    scheduling_poll.issue = Issue.first
    scheduling_poll.scheduling_poll_items.build(:text => '')
    assert_not scheduling_poll.save
    scheduling_poll.scheduling_poll_items.build(:text => ' ')
    assert_not scheduling_poll.save
    scheduling_poll.scheduling_poll_items.build(:text => '\t\r\n')
    assert_not scheduling_poll.save
  end

  test "votes shall return all the votes" do
    scheduling_poll = SchedulingPoll.find(1)

    vote_id = SchedulingVote.arel_table[:id]
    votes = SchedulingVote.where(vote_id.eq(1).or(vote_id.eq(2).or(vote_id.eq(3).or(vote_id.eq(4).or(vote_id.eq(5).or(vote_id.eq(6).or(vote_id.eq(7))))))))
    assert_equal votes.sort, scheduling_poll.votes.sort

    scheduling_poll = SchedulingPoll.find(2)
    assert_empty scheduling_poll.votes
  end

  test "users shall return all the users who vote the poll" do
    scheduling_poll = SchedulingPoll.find(1)
    user_id = User.arel_table[:id]
    users = User.where(user_id.eq(1).or(user_id.eq(2).or(user_id.eq(3))))
    assert_equal users.sort, scheduling_poll.users.sort

    scheduling_poll = SchedulingPoll.find(2)
    assert_empty scheduling_poll.users.sort
  end

  test "activity fetcher shall be return based on :created_at" do
    Project.find(1).enable_module! :scheduling_polls
    Role.all.each do |role|
      role.add_permission! :view_schduling_polls
    end
    fetcher = Redmine::Activity::Fetcher.new(User.find(2))
    fetcher.scope = %w[scheduling_poll]

    expected = SchedulingPoll.all.sort {|a,b| b.created_at <=> a.created_at }
    assert_equal expected, fetcher.events(1.day.ago, Date.today + 1)
  end

  test "votes_by_user shall return all the votes which the user votes" do
    scheduling_poll = SchedulingPoll.find(1)

    user = User.find(1)
    vote_id = SchedulingVote.arel_table[:id]
    votes = SchedulingVote.where(vote_id.eq(1).or(vote_id.eq(2).or(vote_id.eq(3))))
    assert_equal votes.sort, scheduling_poll.votes_by_user(user).sort

    scheduling_poll = SchedulingPoll.find(1)
    user = User.find(5)
    assert_empty scheduling_poll.votes_by_user(user)

    scheduling_poll = SchedulingPoll.find(2)
    user = User.find(1)
    assert_empty scheduling_poll.votes_by_user(user)
  end
end
