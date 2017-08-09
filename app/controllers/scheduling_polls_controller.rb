class SchedulingPollsController < ApplicationController
  unloadable

  before_action :set_scheduling_poll, :only => [:edit, :update, :show, :vote]
  before_action :set_scheduling_poll_by_issue_id, :only => [:show_by_issue]

  accept_api_auth :create, :update, :show, :show_by_issue, :vote

  def new
    begin
      @issue = Issue.find(params[:issue])
      @project = @issue.project
      @poll = SchedulingPoll.find_by(:issue => @issue)
    rescue ActiveRecord::RecordNotFound
      return render_404
    end
    return redirect_to @poll if @poll

    @poll = SchedulingPoll.new(:issue => @issue)
    ensure_allowed_to_vote_scheduling_polls

    raise ::Unauthorized unless User.current.allowed_to?(:vote_schduling_polls, @project, :global => true)

    3.times do |i|
      item = @poll.scheduling_poll_items.build
      item.position = i + 1
    end
    render :edit
  end

  def create
    begin
      @issue = Issue.find(scheduling_poll_params[:issue_id])
      @project = @issue.project
      @poll = SchedulingPoll.find_by(:issue => @issue)
    rescue ActiveRecord::RecordNotFound
      return render_404
    end
    if @poll
      respond_to do |format|
        format.html { return redirect_to @poll }
        format.xml { return render :xml => "<scheduling_poll><status>exist</status><poll><id>#{@poll.id}</id></poll></scheduling_poll>" }
        format.json { return render :json => {:status => :exist, :poll => { :id => @poll.id } } }
      end
    end

    ensure_allowed_to_vote_scheduling_polls
    @poll = SchedulingPoll.new(:issue => @issue)
    SchedulingPoll.transaction do
      # HACK issue:13
      # "SchedulingPoll.new -> @poll.save -> @poll.update" are required to prevent error.
      @poll = SchedulingPoll.new(:issue => @issue)
      if (@poll.save && @poll.update(scheduling_poll_params))
        journal = @poll.issue.init_journal(User.current, l(:notice_scheduling_poll_successful_create, :link_to_poll => "{{scheduling_poll(#{@poll.id})}}"))
        @poll.issue.save
        notify_special_journal_updates(journal)

        respond_to do |format|
          format.html {
            flash[:notice] = l(:notice_successful_create)
            redirect_to @poll
          }
          format.xml { render :text => "<scheduling_poll><status>ok</status><poll><id>#{@poll.id}</id></poll></scheduling_poll>" }
          format.json { render :json => { :status => :ok, :text => l(:notice_successful_create), :poll => { :id => @poll.id } } }
        end
      else
        @poll = nil
        raise ActiveRecord::Rollback
      end
    end

    unless performed?
      @poll = SchedulingPoll.new(scheduling_poll_params)
      1.times do |i|
        item = @poll.scheduling_poll_items.build
        item.position = @poll.scheduling_poll_items.count + i
      end
      respond_to do |format|
        format.html { render :edit }
        format.api { render_validation_errors(@poll) }
      end
    end
  end

  def edit
    raise ::Unauthorized unless User.current.allowed_to?(:vote_schduling_polls, @project, :global => true)
    ensure_allowed_to_vote_scheduling_polls
    1.times do |i|
      item = @poll.scheduling_poll_items.build
      item.position = @poll.scheduling_poll_items.count + i
    end
  end

  def update
    raise ::Unauthorized unless User.current.allowed_to?(:vote_schduling_polls, @project, :global => true)
    ensure_allowed_to_vote_scheduling_polls

    if @poll.update(scheduling_poll_params)
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to @poll }
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.api { render_validation_errors(@poll) }
      end
    end
  end

  def show
    ensure_allowed_to_view_scheduling_polls
    respond_to do |format|
      format.html
      format.api
    end
  end
  
  def show_by_issue
    ensure_allowed_to_view_scheduling_polls
    respond_to do |format|
      format.html { redirect_to @poll }
      format.api { render :action => :show }
    end
  end

  def vote
    ensure_allowed_to_vote_scheduling_polls
    user = User.current

    has_change = @poll.scheduling_poll_items.any? do |item|
      item.vote_value_by_user(user) != (params[:scheduling_vote][item.id.to_s].to_i || 0)
    end

    if has_change
      @poll.scheduling_poll_items.each do |item|
        item.vote(user, params[:scheduling_vote][item.id.to_s])
      end
      unless params[:vote_comment].empty?
        journal = @poll.issue.init_journal(user, params[:vote_comment])
        @poll.issue.save
        notify_special_journal_updates(journal)
      end

      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_scheduling_vote)
          redirect_to :action => 'show'
        }
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render_error l(:error_scheduling_vote_no_change) }
        format.api { render_api_errors l(:error_scheduling_vote_no_change) }
      end
    end
  end

  private
  def set_scheduling_poll
    @poll = SchedulingPoll.find(params[:id])
    @issue = @poll.issue
    @project = @poll.issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def set_scheduling_poll_by_issue_id
    @poll = SchedulingPoll.find_by(:issue_id => params[:issue_id])
    raise ActiveRecord::RecordNotFound if @poll.nil?
    @issue = @poll.issue
    @project = @poll.issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def ensure_allowed_to_view_scheduling_polls
    raise ::Unauthorized unless User.current.allowed_to?(:view_schduling_polls, @project, :global => true)
    raise ::Unauthorized unless @poll.issue.visible?(User.current)
  end
  def ensure_allowed_to_vote_scheduling_polls
    raise ::Unauthorized unless User.current.allowed_to?(:vote_schduling_polls, @project, :global => true)
  end

  def scheduling_poll_params
    params.require(:scheduling_poll).permit(:issue_id, :scheduling_poll_items_attributes => [:id, :text, :position, :_destroy])
  end

  def notify_special_journal_updates(journal)
    # Notify to slack
    if Redmine::Plugin.installed?(:redmine_slack)
      [].tap do |response|
        Redmine::Hook.listeners.each do |listener|
          if listener.kind_of?(SlackListener)
            response << listener.controller_issues_edit_after_save(
              :params => nil, # :redmine_slack does not use :params as of now
              :issue => @issue,
              :journal => journal,
            )
          end
        end
      end
    end
  end

end
