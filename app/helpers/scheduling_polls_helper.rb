module SchedulingPollsHelper

  def vote_value(val=0)
    { 1 => 'no', 2 => 'maybe', 3 => 'ok' }[val] || '-'
  end

end
