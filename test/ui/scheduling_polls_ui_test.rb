# frozen_string_literal: true
require File.expand_path('../../test_helper', __FILE__)
return if Rails.version > "4" # do not run UI test for redmine4+

require File.expand_path('test/ui/base', Rails.root)

class Redmine::UiTest::SchedulingPollsTest < Redmine::UiTest::Base
  fixtures :users, :issues, :projects, :trackers,
    :enabled_modules, :members, :member_roles, :roles,
    :scheduling_polls, :scheduling_poll_items, :scheduling_votes

  def setup
    User.current = nil
    Project.find(1).enable_module! :scheduling_polls
    Role.all.each do |role|
      role.add_permission! :view_schduling_polls
      role.add_permission! :vote_schduling_polls
    end

    @dateformat = Setting.plugin_redmine_scheduling_poll["scheduling_poll_item_date_format"]
  end

  def test_vote_from_show
    log_user('jsmith', 'jsmith')

    visit '/scheduling_polls/1/show'
    page.first('#scheduling_vote_3_1').click
    page.first('#scheduling-poll form input[type="submit"]').click

    assert page.has_selector?('#flash_notice', :text => 'Successful vote.')
    assert page.has_selector?('#scheduling_vote_3_1:checked', :count => 1)
    assert_equal [[1, 2], [2, 3], [3, 1]], SchedulingPoll.find(1).votes_by_user(User.find(2)).pluck(:scheduling_poll_item_id, :value)

    # issue cat-in-136/redmine_scheduling_poll#23 from here

    page.first('#scheduling-poll form input[type="submit"]').click

    page.first('#scheduling_vote_3_2').click
    page.first('#scheduling-poll form input[type="submit"]').click

    assert page.has_selector?('#flash_notice', :text => 'Successful vote.')
    assert page.has_selector?('#scheduling_vote_3_2:checked', :count => 1)
    assert_equal [[1, 2], [2, 3], [3, 2]], SchedulingPoll.find(1).votes_by_user(User.find(2)).pluck(:scheduling_poll_item_id, :value)
  end

  def test_edit_toggle_date_picker
    log_user('jsmith', 'jsmith')

    visit '/scheduling_polls/1/edit'
    assert page.has_selector?('input[type=text].scheduling_poll_item_text', :count => 4)
    assert page.has_selector?('input[type=text].scheduling_poll_item_text:not([readonly])', :count => 1)
    assert page.has_selector?('.ui-datepicker-trigger', :count => 1)
    assert page.has_selector?('#ui-datepicker-div', :count => 0, :visible => true)

    page.first('.ui-datepicker-trigger').click
    assert page.has_selector?('#ui-datepicker-div', :count => 1, :visible => true)
    page.first('.ui-datepicker-trigger').click
    assert page.has_selector?('#ui-datepicker-div', :count => 0, :visible => true)

    page.first('.ui-datepicker-trigger').click
    page.first('#ui-datepicker-div button[data-handler=today]').click
    page.first('#ui-datepicker-div .ui-datepicker-today').click
    assert page.has_selector?('#ui-datepicker-div', :count => 0, :visible => true)
    assert_equal page.evaluate_script("$.datepicker.formatDate('#{@dateformat}', new Date())"), page.first('input[type=text].scheduling_poll_item_text:not([readonly])').value

    page.find('a[onclick*=scheduling_polls_update_date_picker]').click
    assert page.has_selector?('.ui-datepicker-trigger', :count => 0)
    assert page.has_selector?('#ui-datepicker-div', :count => 0, :visible => true)

    page.find('a[onclick*=scheduling_polls_update_date_picker]').click
    assert page.has_selector?('.ui-datepicker-trigger', :count => 1)
    assert page.has_selector?('#ui-datepicker-div', :count => 0, :visible => true)

    page.find('.ui-datepicker-trigger').click
    assert page.has_selector?('#ui-datepicker-div', :count => 1, :visible => true)
  end

  # TODO test reorder
end
