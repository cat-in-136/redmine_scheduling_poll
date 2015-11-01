class SchedulingPollsController < ApplicationController
  unloadable

  before_action :set_scheduling_poll, :only => [:edit, :update, :show, :vote]
  before_action :ensure_allowed_to_view_scheduling_polls, :only => [:show]
  before_action :ensure_allowed_to_vote_scheduling_polls, :only => [:edit, :update, :vote]

  def new
    @issue = Issue.find(params[:issue])
    @project = @issue.project
    @poll = SchedulingPoll.find_by(:issue => @issue)
    redirect_to @poll if @poll
    @poll = SchedulingPoll.new(:issue => @issue)
    ensure_allowed_to_vote_scheduling_polls

    raise ::Unauthorized unless User.current.allowed_to?(:vote_schduling_polls, @project, :global => true)

    3.times do
      @poll.scheduling_poll_item.build
    end
    render :edit
  end

  def create
    redirect_to :action => 'vote' if SchedulingPoll.find_by(:issue_id => scheduling_poll_params[:issue_id])
    @poll = SchedulingPoll.new(scheduling_poll_params)
    ensure_allowed_to_vote_scheduling_polls
    @project = @poll.issue.project

    raise ::Unauthorized unless User.current.allowed_to?(:vote_schduling_polls, @project, :global => true)

    if @poll.save
      flash[:notice] = 'Poll created.'
      redirect_to @poll
    else
      render :new
    end
  end

  def edit
    raise ::Unauthorized unless User.current.allowed_to?(:vote_schduling_polls, @project, :global => true)
    1.times do
      @poll.scheduling_poll_item.build
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
  end

  def vote
    user = User.current
    @poll.scheduling_poll_item.each do |item|
      item.vote(user, params[:scheduling_vote][item.id.to_s])
    end

    flash[:notice] = 'Vote saved.'
    redirect_to :action => 'show'
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
    params.require(:scheduling_poll).permit(:issue_id, :scheduling_poll_item_attributes => [:id, :text, :_destroy])
  end


end
