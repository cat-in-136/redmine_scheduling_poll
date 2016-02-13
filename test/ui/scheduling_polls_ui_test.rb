require File.expand_path('../../test_helper', __FILE__)
require File.expand_path('test/ui/base', Rails.root)

class Redmine::UiTest::SchedulingPollsTest < Redmine::UiTest::Base
  fixtures :users, :issues, :projects, :roles,
    :scheduling_polls, :scheduling_poll_items, :scheduling_votes

  def setup
    User.current = User.find(2)
    Project.find(1).enable_module! :scheduling_polls
    Role.find(4).add_permission! :view_schduling_polls
    Role.find(4).add_permission! :vote_schduling_polls

    @dateformat = Setting.plugin_redmine_scheduling_poll["scheduling_poll_item_date_format"]
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
