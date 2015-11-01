class SchedulingPollsController < ApplicationController
  unloadable

  before_action :set_scheduling_poll, :only => [:edit, :update, :show, :vote]

  def new
    @issue = Issue.find(params[:issue])
    @poll = SchedulingPoll.find_by(:issue => @issue)
    redirect_to @poll if @poll
    @poll = SchedulingPoll.new(:issue => @issue)

    3.times do
      @poll.scheduling_poll_item.build
    end
    render :edit
  end

  def create
    redirect_to :action => 'vote' if SchedulingPoll.find_by(:issue_id => scheduling_poll_params[:issue_id])
    @poll = SchedulingPoll.new(scheduling_poll_params)

    if @poll.save
      flash[:notice] = 'Poll created.'
      redirect_to @poll
    else
      render :new
    end
  end

  def edit
    1.times do
      @poll.scheduling_poll_item.build
    end
  end

  def update
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
  end

  def scheduling_poll_params
    params.require(:scheduling_poll).permit(:issue_id, :scheduling_poll_item_attributes => [:id, :text, :_destroy])
  end


end
