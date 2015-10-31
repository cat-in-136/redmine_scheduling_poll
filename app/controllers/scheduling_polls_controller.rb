class SchedulingPollsController < ApplicationController
  unloadable

  def show
    @poll = SchedulingPoll.find(params[:id])
  end

  def vote
    poll = SchedulingPoll.find(params[:id])
    user = User.current
    poll.scheduling_poll_item.each do |item|
      item.vote(user, params[:scheduling_vote][item.id.to_s])
    end

    flash[:notice] = 'Vote saved.'
    redirect_to :action => 'show'
  end
end
