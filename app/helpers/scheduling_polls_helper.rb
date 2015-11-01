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

  def link_to_add_scheduling_poll_item_fields_function(name, f, option=nil, &block) # :yields: f_item
    opt = { :code_tmpl => '$(this).before(%S)' }.merge(option)

    fields = f.fields_for(:scheduling_poll_item, SchedulingPollItem.new, :child_index => "%CHILD_INDEX%", &block)
    js_inner_html = "\"#{escape_javascript(fields)}\".replace(/%CHILD_INDEX%/g, new Date().getTime())"
    js_func = opt[:code_tmpl].sub(/%S/, js_inner_html)

    link_to_function name, js_func
  end

end
