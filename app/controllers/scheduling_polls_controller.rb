class SchedulingPollsController < ApplicationController
  unloadable

  def show
    @poll = SchedulingPoll.find(params[:id])
  end

  def vote
  end
end
