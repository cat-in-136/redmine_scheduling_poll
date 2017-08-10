require File.expand_path('../../test_helper', __FILE__)

class SchedulingPollsControllerTest < ActionController::TestCase
  NOT_EXIST_ITEM = 9999

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

    # install Fake Redmine Slack
    unless Redmine::Plugin.installed?(:redmine_slack)
      Redmine::Plugin.register :redmine_slack do
        name 'Fake Redmine Slack'
        version '0.2'
      end
      eval 'module ::SlackListener end'
      listener_klass = Class.new
      listener_klass.include Singleton
      listener_klass.include ::SlackListener
      listener_klass.any_instance.stubs(:controller_issues_edit_after_save)
      Redmine::Hook.add_listener(listener_klass)
    end
  end

  def teardown
    # Monkey un-patching of "visible_with_scheduling_poll_test?"
    Issue.module_eval do
      alias_method :visible?, :visible_without_scheduling_poll_test?
    end

    # uninstall Fake Redmine Slack
    if Redmine::Plugin.find(:redmine_slack).name == 'Fake Redmine Slack'
      Redmine::Plugin.unregister(:redmine_slack)
      Redmine::Hook.class_variable_get(:@@listener_classes).reject! do |klass|
        klass.include? ::SlackListener
      end
      Redmine::Hook.clear_listeners_instances
    end
  end

  test "new" do
    get :new, :issue => NOT_EXIST_ITEM
    assert_response 404

    get :new, :issue => 1
    assert_redirected_to :action => :show, :id => SchedulingPoll.find(1)

    assert SchedulingPoll.find(1).destroy
    get :new, :issue => 1
    assert_response :success
    assert_template :edit

    refute_nil assigns(:poll)
    assert_equal 0, assigns(:poll).scheduling_poll_items.count # no item in DB.
    assert_equal 3, assigns(:poll).scheduling_poll_items.length # one more item
  end

  test "create" do
    post :create, :scheduling_poll => {:issue_id => NOT_EXIST_ITEM, :scheduling_poll_items_attributes => []}
    assert_response 404

    poll = SchedulingPoll.find_by(:issue => 1)
    refute_nil poll
    post :create, :scheduling_poll => {:issue_id => 1, :scheduling_poll_items_attributes => []}
    assert_redirected_to :action => :show, :id => SchedulingPoll.find_by(:issue => Issue.find(1))
    assert_nil flash[:notice]

    assert poll.destroy
    poll = nil
    post :create, :scheduling_poll => {:issue_id => 1, :scheduling_poll_items_attributes => [{:text => "text1", :position => 1}, {:text => "text2", :position => 2}, {:text => "", :position => 3}]}
    poll = SchedulingPoll.find_by(:issue => 1)
    refute_nil poll
    assert_equal ["text1", "text2"], poll.scheduling_poll_items.map {|v| v.text }
    assert_equal [1, 2], poll.scheduling_poll_items.map {|v| v.position }
    assert_redirected_to :action => :show, :id => poll
    refute_nil flash[:notice]

    assert poll.destroy
    poll = nil
    SchedulingPoll.any_instance.stubs(:update).returns(nil)
    post :create, :scheduling_poll => {:issue_id => 1, :scheduling_poll_items_attributes => []}
    assert_nil SchedulingPoll.find_by(:issue => 1)
    assert_template :edit
  end

  test "create.json" do
    with_settings :rest_api_enabled => '1' do
      post :create, :scheduling_poll => {:issue_id => NOT_EXIST_ITEM, :scheduling_poll_items_attributes => []}, :format => :json, :key => User.current.api_key
      assert_response 404
  
      poll = SchedulingPoll.find_by(:issue => 1)
      refute_nil poll
      post :create, :scheduling_poll => {:issue_id => 1, :scheduling_poll_items_attributes => []}, :format => :json, :key => User.current.api_key
      assert_response :success
      json = ActiveSupport::JSON.decode(response.body)
      assert_equal 'exist', json['status']
      assert_equal poll.id, json['poll']['id']

      assert poll.destroy
      poll = nil
      post :create, :scheduling_poll => {:issue_id => 1, :scheduling_poll_items_attributes => [{:text => "text1", :position => 1}, {:text => "text2", :position => 2}, {:text => "", :position => 3}]}, :format => :json, :key => User.current.api_key
      poll = SchedulingPoll.find_by(:issue => 1)
      refute_nil poll
      assert_equal ["text1", "text2"], poll.scheduling_poll_items.map {|v| v.text }
      assert_equal [1, 2], poll.scheduling_poll_items.map {|v| v.position }
      assert_response :success
      json = ActiveSupport::JSON.decode(response.body)
      assert_equal 'ok', json['status']
      assert_equal poll.id, json['poll']['id']
    end
  end

  test "create.xml" do
    with_settings :rest_api_enabled => '1' do
      post :create, :scheduling_poll => {:issue_id => NOT_EXIST_ITEM, :scheduling_poll_items_attributes => []}, :format => :xml, :key => User.current.api_key
      assert_response 404

      poll = SchedulingPoll.find_by(:issue => 1)
      refute_nil poll
      post :create, :scheduling_poll => {:issue_id => 1, :scheduling_poll_items_attributes => []}, :format => :xml, :key => User.current.api_key
      assert_response :success
      assert_equal 'application/xml', response.content_type
      assert_match /exist/, response.body

      assert poll.destroy
      poll = nil
      post :create, :scheduling_poll => {:issue_id => 1, :scheduling_poll_items_attributes => [{:text => "text1", :position => 1}, {:text => "text2", :position => 2}, {:text => "", :position => 3}]}, :format => :xml, :key => User.current.api_key
      poll = SchedulingPoll.find_by(:issue => 1)
      refute_nil poll
      assert_equal ["text1", "text2"], poll.scheduling_poll_items.map {|v| v.text }
      assert_equal [1, 2], poll.scheduling_poll_items.map {|v| v.position }
      assert_response :success
      assert_equal 'application/xml', response.content_type
      assert_match /ok/, response.body
    end
  end

  test "edit" do
    get :edit, :id => NOT_EXIST_ITEM
    assert_response 404

    get :edit, :id => 1
    assert_response :success
    assert_template :edit

    refute_nil assigns(:poll)
    assert_equal 3, assigns(:poll).scheduling_poll_items.count # 3 items in DB.
    assert_equal 4, assigns(:poll).scheduling_poll_items.length # one more item
  end

  test "update" do
    patch :update, :id => NOT_EXIST_ITEM, :scheduling_poll => {:issue_id => NOT_EXIST_ITEM}
    assert_response 404

    poll = SchedulingPoll.find_by(:issue => 1)
    refute_nil poll
    patch :update, :id => 1, :scheduling_poll => {:issue_id => 1, :scheduling_poll_items_attributes => [{:id => 1, :position => 1}, {:id => 2, :position => 2, :_destroy => 1}, {:id => 3, :position => 3, :_destroy => 0}, {:text => "text", :position => 4}, {:text => "", :position => 5}]}
    assert_equal "text", SchedulingPollItem.last.text
    assert_raise ActiveRecord::RecordNotFound do SchedulingPollItem.find(2) end
    assert_equal [SchedulingPollItem.find(1), SchedulingPollItem.find(3), SchedulingPollItem.last], poll.scheduling_poll_items.sorted.to_a
    assert_redirected_to :action => :show, :id => SchedulingPoll.find_by(:issue => Issue.find(1))
    refute_nil flash[:notice]

    SchedulingPoll.any_instance.stubs(:update).returns(nil)
    patch :update, :id => 1, :scheduling_poll => {:issue_id => 1, :scheduling_poll_items_attributes => [{:id => 1, :_destroy => 1}]}
    refute_nil SchedulingPollItem.find(1)
    assert_template :edit
  end

  test "update.json" do
    with_settings :rest_api_enabled => '1' do
      patch :update, :id => NOT_EXIST_ITEM, :scheduling_poll => {:issue_id => NOT_EXIST_ITEM}, :format => :json, :key => User.current.api_key
      assert_response 404

      poll = SchedulingPoll.find_by(:issue => 1)
      refute_nil poll
      patch :update, :id => 1, :scheduling_poll => {:issue_id => 1, :scheduling_poll_items_attributes => [{:id => 1, :position => 1}, {:id => 2, :position => 2, :_destroy => 1}, {:id => 3, :position => 3, :_destroy => 0}, {:text => "text", :position => 4}, {:text => "", :position => 5}]}, :format => :json, :key => User.current.api_key
      assert_response :success
      assert_empty response.body
    end
  end

  test "update.xml" do
    with_settings :rest_api_enabled => '1' do
      patch :update, :id => NOT_EXIST_ITEM, :scheduling_poll => {:issue_id => NOT_EXIST_ITEM}, :format => :xml, :key => User.current.api_key
      assert_response 404

      poll = SchedulingPoll.find_by(:issue => 1)
      refute_nil poll
      patch :update, :id => 1, :scheduling_poll => {:issue_id => 1, :scheduling_poll_items_attributes => [{:id => 1, :position => 1}, {:id => 2, :position => 2, :_destroy => 1}, {:id => 3, :position => 3, :_destroy => 0}, {:text => "text", :position => 4}, {:text => "", :position => 5}]}, :format => :xml, :key => User.current.api_key
      assert_response :success
      assert_empty response.body
    end
  end

  test "show" do
    get :show, :id => 1
    assert_response :success
    assert_template :show

    get :show, :id => NOT_EXIST_ITEM # not-exist issue
    assert_response 404
  end

  test "show.api" do
    with_settings :rest_api_enabled => '1' do
      get :show, :id => 1, :format => :json, :key => User.current.api_key
      assert_response :success
      json = ActiveSupport::JSON.decode(response.body)
      assert_kind_of Hash, json['scheduling_poll']
      assert_equal 1, json['scheduling_poll']['id']
      assert_equal 1, json['scheduling_poll']['issue']['id']
      assert_kind_of Array, json['scheduling_poll']['scheduling_poll_items']
      assert_equal 1, json['scheduling_poll']['scheduling_poll_items'][0]['id']
      assert_equal SchedulingPollItem.find(1).text, json['scheduling_poll']['scheduling_poll_items'][0]['text']
      assert_kind_of Array, json['scheduling_poll']['scheduling_poll_items'][0]['scheduling_votes']
      assert_equal 1, json['scheduling_poll']['scheduling_poll_items'][0]['scheduling_votes'][0]['user']['id']
      assert_equal [{
        'value' => 3,
        'text' => Setting.plugin_redmine_scheduling_poll["scheduling_vote_value_3"],
      }][0], json['scheduling_poll']['scheduling_poll_items'][0]['scheduling_votes'][0]['value']
      assert_equal 2, json['scheduling_poll']['scheduling_poll_items'][0]['scheduling_votes'][1]['user']['id']
      assert_equal [{
        'value' => 2,
        'text' => Setting.plugin_redmine_scheduling_poll["scheduling_vote_value_2"],
      }][0], json['scheduling_poll']['scheduling_poll_items'][0]['scheduling_votes'][1]['value']

      get :show, :id => 1, :format => :xml, :key => User.current.api_key
      assert_response :success
      assert_equal 'application/xml', response.content_type

      get :show, :id => NOT_EXIST_ITEM, :format => :json, :key => User.current.api_key # not-exist issue
      assert_response 404

      get :show, :id => NOT_EXIST_ITEM, :format => :xml, :key => User.current.api_key # not-exist issue
      assert_response 404
    end
  end

  test "show_by_issue" do
    get :show_by_issue, :issue_id => 1
    assert_redirected_to :action => :show, :id => 1

    get :show_by_issue, :issue_id => NOT_EXIST_ITEM # not-exist issue
    assert_response 404
  end

  test "show_by_issue.api" do
    with_settings :rest_api_enabled => '1' do
      get :show_by_issue, :issue_id => 1, :format => :json, :key => User.current.api_key
      assert_response :success
      json = ActiveSupport::JSON.decode(response.body)
      assert_kind_of Hash, json['scheduling_poll']
      assert_equal 1, json['scheduling_poll']['id']
      assert_equal 1, json['scheduling_poll']['issue']['id']
      assert_kind_of Array, json['scheduling_poll']['scheduling_poll_items']
      assert_equal 1, json['scheduling_poll']['scheduling_poll_items'][0]['id']
      assert_equal SchedulingPollItem.find(1).text, json['scheduling_poll']['scheduling_poll_items'][0]['text']
      assert_kind_of Array, json['scheduling_poll']['scheduling_poll_items'][0]['scheduling_votes']
      assert_equal 1, json['scheduling_poll']['scheduling_poll_items'][0]['scheduling_votes'][0]['user']['id']
      assert_equal [{
        'value' => 3,
        'text' => Setting.plugin_redmine_scheduling_poll["scheduling_vote_value_3"],
      }][0], json['scheduling_poll']['scheduling_poll_items'][0]['scheduling_votes'][0]['value']
      assert_equal 2, json['scheduling_poll']['scheduling_poll_items'][0]['scheduling_votes'][1]['user']['id']
      assert_equal [{
        'value' => 2,
        'text' => Setting.plugin_redmine_scheduling_poll["scheduling_vote_value_2"],
      }][0], json['scheduling_poll']['scheduling_poll_items'][0]['scheduling_votes'][1]['value']
      assert_response :success

      get :show_by_issue, :issue_id => 1, :format => :xml, :key => User.current.api_key
      assert_response :success
      assert_equal 'application/xml', response.content_type

      get :show_by_issue, :issue_id => NOT_EXIST_ITEM, :format => :json, :key => User.current.api_key # not-exist issue
      assert_response 404

      get :show_by_issue, :issue_id => NOT_EXIST_ITEM, :format => :xml, :key => User.current.api_key # not-exist issue
      assert_response 404
    end
  end

  test "vote" do
    assert_nil SchedulingPollItem.find(4).vote_by_user(User.current)
    assert_nil SchedulingPollItem.find(5).vote_by_user(User.current)
    assert_nil SchedulingPollItem.find(6).vote_by_user(User.current)

    post :vote, :id => 2, :scheduling_vote => { '4' => '0', '5' => '1', '6' => '2' }, :vote_comment => ''
    assert_redirected_to :action => :show, :id => 2
    refute_nil flash[:notice]
    assert_nil SchedulingPollItem.find(4).vote_by_user(User.current)
    assert_equal 1, SchedulingPollItem.find(5).vote_value_by_user(User.current)
    assert_equal 2, SchedulingPollItem.find(6).vote_value_by_user(User.current)

    post :vote, :id => 2, :scheduling_vote => { '4' => '2', '5' => '1', '6' => '0' }, :vote_comment => '**vote test msg**'
    assert_redirected_to :action => :show, :id => 2
    refute_nil flash[:notice]
    assert_equal 2, SchedulingPollItem.find(4).vote_value_by_user(User.current)
    assert_equal 1, SchedulingPollItem.find(5).vote_value_by_user(User.current)
    assert_nil SchedulingPollItem.find(6).vote_by_user(User.current)
    # Journal does not work in the test (i.e. empty)

    post :vote, :id => 2, :scheduling_vote => { '4' => '2', '5' => '1', '6' => '0' }, :vote_comment => '' # no-change
    assert_response 500
  end

  test "vote.json" do
    with_settings :rest_api_enabled => '1' do
      assert_nil SchedulingPollItem.find(4).vote_by_user(User.current)
      assert_nil SchedulingPollItem.find(5).vote_by_user(User.current)
      assert_nil SchedulingPollItem.find(6).vote_by_user(User.current)

      post :vote, :id => 2, :scheduling_vote => { '4' => '0', '5' => '1', '6' => '2' }, :vote_comment => '', :format => :json, :key => User.current.api_key
      assert_response :success
      assert_empty response.body
      assert_nil SchedulingPollItem.find(4).vote_by_user(User.current)
      assert_equal 1, SchedulingPollItem.find(5).vote_value_by_user(User.current)
      assert_equal 2, SchedulingPollItem.find(6).vote_value_by_user(User.current)

      post :vote, :id => 2, :scheduling_vote => { '4' => '2', '5' => '1', '6' => '0' }, :vote_comment => '**vote test msg**', :format => :json, :key => User.current.api_key
      assert_response :success
      assert_empty response.body
      assert_equal 2, SchedulingPollItem.find(4).vote_value_by_user(User.current)
      assert_equal 1, SchedulingPollItem.find(5).vote_value_by_user(User.current)
      assert_nil SchedulingPollItem.find(6).vote_by_user(User.current)
      # Journal does not work in the test (i.e. empty)

      post :vote, :id => 2, :scheduling_vote => { '4' => '2', '5' => '1', '6' => '0' }, :vote_comment => '', :format => :json, :key => User.current.api_key # no-change
      assert_response 422
    end
  end

  test "vote.xml" do
    with_settings :rest_api_enabled => '1' do
      assert_nil SchedulingPollItem.find(4).vote_by_user(User.current)
      assert_nil SchedulingPollItem.find(5).vote_by_user(User.current)
      assert_nil SchedulingPollItem.find(6).vote_by_user(User.current)

      post :vote, :id => 2, :scheduling_vote => { '4' => '0', '5' => '1', '6' => '2' }, :vote_comment => '', :format => :xml, :key => User.current.api_key
      assert_response :success
      assert_empty response.body
      assert_nil SchedulingPollItem.find(4).vote_by_user(User.current)
      assert_equal 1, SchedulingPollItem.find(5).vote_value_by_user(User.current)
      assert_equal 2, SchedulingPollItem.find(6).vote_value_by_user(User.current)

      post :vote, :id => 2, :scheduling_vote => { '4' => '2', '5' => '1', '6' => '0' }, :vote_comment => '**vote test msg**', :format => :xml, :key => User.current.api_key
      assert_response :success
      assert_empty response.body
      assert_equal 2, SchedulingPollItem.find(4).vote_value_by_user(User.current)
      assert_equal 1, SchedulingPollItem.find(5).vote_value_by_user(User.current)
      assert_nil SchedulingPollItem.find(6).vote_by_user(User.current)
      # Journal does not work in the test (i.e. empty)

      post :vote, :id => 2, :scheduling_vote => { '4' => '2', '5' => '1', '6' => '0' }, :vote_comment => '', :format => :xml, :key => User.current.api_key # no-change
      assert_response 422
    end
  end
end
