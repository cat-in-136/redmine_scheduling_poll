module SchedulingPollsHelper

  def scheduling_vote_value(val=0)
    val = val.value if val.kind_of? SchedulingVote
    { 1 => 'no', 2 => 'maybe', 3 => 'ok' }[val] || '-'
  end

  def scheduling_vote_values_array
    vote_value_0 = scheduling_vote_value(0)
    vote_value_array = []
    1.step(nil, 1).each do |v|
      vote_value_v = scheduling_vote_value(v)
      if (vote_value_v == vote_value_0)
        break
      else
        vote_value_array << [v, vote_value_v]
      end
    end
    vote_value_array.reverse
  end

end
