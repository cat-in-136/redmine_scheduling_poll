class SchedulingPollsController < ApplicationController
  unloadable

  before_action :set_scheduling_poll, :only => [:edit, :update, :show, :vote]
  before_action :ensure_allowed_to_view_scheduling_polls, :only => [:show]
  before_action :ensure_allowed_to_vote_scheduling_polls, :only => [:edit, :update, :vote]

  def new
    @issue = Issue.find(params[:issue])
    @project = @issue.project
    @poll = SchedulingPoll.find_by(:issue => @issue)
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
    @poll = SchedulingPoll.find_by(:issue_id => scheduling_poll_params[:issue_id])
    return redirect_to @poll if @poll
    @poll = SchedulingPoll.new(scheduling_poll_params)
    ensure_allowed_to_vote_scheduling_polls
    @project = @poll.issue.project

    raise ::Unauthorized unless User.current.allowed_to?(:vote_schduling_polls, @project, :global => true)

    if @poll.save
      journal = @poll.issue.init_journal(User.current, "{{scheduling_poll(#{@poll.id})}} created for the issue.")
      @poll.issue.save

      respond_to do |format|
        format.html {
          flash[:notice] = 'Poll created.'
          redirect_to @poll
        }
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.api { render_validation_errors(@poll) }
      end
    end
  end

  def edit
    raise ::Unauthorized unless User.current.allowed_to?(:vote_schduling_polls, @project, :global => true)
    1.times do |i|
      item = @poll.scheduling_poll_items.build
      item.position = @poll.scheduling_poll_items.count + i
    end
  end

  def update
    raise ::Unauthorized unless User.current.allowed_to?(:vote_schduling_polls, @project, :global => true)

    if @poll.update(scheduling_poll_params)
      flash[:notice] = 'Poll updated.'
      redirect_to @poll
    else
      render :edit
    end
  end

  def show
    respond_to do |format|
      format.html
      format.api
    end
  end

  def vote
    user = User.current
    @poll.scheduling_poll_items.each do |item|
      item.vote(user, params[:scheduling_vote][item.id.to_s])
    end
    unless params[:vote_comment].empty?
      journal = @poll.issue.init_journal(user, params[:vote_comment])
      @poll.issue.save
    end

    respond_to do |format|
      format.html {
        flash[:notice] = 'Vote saved.'
        redirect_to :action => 'show'
      }
      format.api { render_api_ok }
    end
  end

  private
  def set_scheduling_poll
    @poll = SchedulingPoll.find(params[:id])
    @project = @poll.issue.project
  end
  def ensure_allowed_to_view_scheduling_polls
    raise ::Unauthorized unless User.current.allowed_to?(:view_schduling_polls, @project, :global => true)
  end
  def ensure_allowed_to_vote_scheduling_polls
    raise ::Unauthorized unless User.current.allowed_to?(:vote_schduling_polls, @project, :global => true)
  end

  def scheduling_poll_params
    params.require(:scheduling_poll).permit(:issue_id, :scheduling_poll_items_attributes => [:id, :text, :position, :_destroy])
  end


end
