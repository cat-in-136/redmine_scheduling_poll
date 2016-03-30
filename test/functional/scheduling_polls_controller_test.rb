require File.expand_path('../../test_helper', __FILE__)

class SchedulingPollsControllerTest < ActionController::TestCase
  fixtures :users, :issues, :projects, :roles,
    :scheduling_polls, :scheduling_poll_items, :scheduling_votes

  def setup
    User.current = User.find(2)
    @request.session[:user_id] = User.current.id
    Project.find(1).enable_module! :scheduling_polls
    role = Role.find(4)
    role.add_permission! :view_schduling_polls
    role.add_permission! :vote_schduling_polls

    # FIXME Monkey patching to pass issue#visibule?
    Issue.module_eval do
      def visible_with_scheduling_poll_test?(usr=nil)
        !self.is_private? || (self.author == (usr || User.current))
      end
      alias_method_chain :visible?, :scheduling_poll_test
    end
  end

  def teardown
    # Monkey un-patching of "visible_with_scheduling_poll_test?"
    Issue.module_eval do
      alias_method :visible?, :visible_without_scheduling_poll_test?
    end
  end

  test "new" do
    get :new, :issue => 1
    assert_redirected_to :action => :show, :id => SchedulingPoll.find(1)

    assert SchedulingPoll.find(1).destroy
    get :new, :issue => 1
    assert_response :success
    assert_template :edit

    assert_not_nil assigns(:poll)
    assert_equal 0, assigns(:poll).scheduling_poll_items.count # no item in DB.
    assert_equal 3, assigns(:poll).scheduling_poll_items.length # one more item
  end

  test "create" do
    poll = SchedulingPoll.find_by(:issue => 1)
    assert_not_nil poll
    post :create, :scheduling_poll => {:issue_id => 1, :scheduling_poll_items_attributes => []}
    assert_redirected_to :action => :show, :id => SchedulingPoll.find_by(:issue => Issue.find(1))
    assert_nil flash[:notice]

    assert poll.destroy
    poll = nil
    post :create, :scheduling_poll => {:issue_id => 1, :scheduling_poll_items_attributes => [{:text => "text1", :position => 1}, {:text => "text2", :position => 2}, {:text => "", :position => 3}]}
    poll = SchedulingPoll.find_by(:issue => 1)
    assert_not_nil poll
    assert_equal ["text1", "text2"], poll.scheduling_poll_items.map {|v| v.text }
    assert_equal [1, 2], poll.scheduling_poll_items.map {|v| v.position }
    assert_redirected_to :action => :show, :id => poll
    assert_not_nil flash[:notice]
  end

  test "edit" do
    get :edit, :id => 1
    assert_response :success
    assert_template :edit

    assert_not_nil assigns(:poll)
    assert_equal 3, assigns(:poll).scheduling_poll_items.count # 3 items in DB.
    assert_equal 4, assigns(:poll).scheduling_poll_items.length # one more item
  end

  test "update" do
    poll = SchedulingPoll.find_by(:issue => 1)
    assert_not_nil poll
    patch :update, :id => 1, :scheduling_poll => {:issue_id => 1, :scheduling_poll_items_attributes => [{:id => 1, :position => 1}, {:id => 2, :position => 2, :_destroy => 1}, {:id => 3, :position => 3, :_destroy => 0}, {:text => "text", :position => 4}, {:text => "", :position => 5}]}
    assert_equal "text", SchedulingPollItem.last.text
    assert_raise ActiveRecord::RecordNotFound do SchedulingPollItem.find(2) end
    assert_equal [SchedulingPollItem.find(1), SchedulingPollItem.find(3), SchedulingPollItem.last], poll.scheduling_poll_items.sorted.to_a
    assert_redirected_to :action => :show, :id => SchedulingPoll.find_by(:issue => Issue.find(1))
    assert_not_nil flash[:notice]
  end

  test "show" do
    get :show, :id => 1
    assert_response :success
    assert_template :show

    get :show, :id => 9999 # not-exist issue
    assert_response 404
  end
end
