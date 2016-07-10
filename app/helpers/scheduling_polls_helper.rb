module SchedulingPollsHelper

  def scheduling_vote_value(val=0)
    val = val.value if val.kind_of? SchedulingVote
    str = ''
    if ((val.present?) && (0 < val) && (val <= 5))
      str = Setting.plugin_redmine_scheduling_poll["scheduling_vote_value_#{val}"]
    end
    str = '-' if str.blank?
    str
  end

  def scheduling_vote_values_array
    vote_value_array = []
    1.step(5, 1).each do |v|
      vote_value_v = scheduling_vote_value(v)
      vote_value_array << [v, vote_value_v] unless vote_value_v == '-'
    end
    vote_value_array.reverse
  end

  def render_date_related_parameter_of_issue(issue)
    s = ''
    s << '<h3>' << link_to(issue, issue_path(issue)) << '</h3>'
    s << '<div>'
    unless issue.disabled_core_fields.include?('start_date')
      s << '<p><strong>' << h(l(:field_start_date)) << '</strong></p>'
      s << content_tag(:span, format_date(issue.start_date), :class => 'start-date')
    end
    unless issue.disabled_core_fields.include?('due_date')
      s << '<p><strong>' << h(l(:field_due_date)) << '</strong></p>'
      s << content_tag(:span, format_date(issue.due_date), :class => 'due-date')
    end
    # show date-related custom field values (requires redmine >= 3.1)
    # if Gem::Version.new([Redmine::VERSION::MAJOR, Redmine::VERSION::MINOR].join(".")) >= Gem::Version.new("3.1") # redmine >= 3.1
    if CustomFieldsController.helpers.methods.include?(:custom_field_name_tag)
      issue.visible_custom_field_values.each do |value|
        if value.custom_field.field_format == "date"
          s << '<p><strong>' << h(CustomFieldsController.helpers.custom_field_name_tag(value.custom_field)) << '</strong></p>'
          s << content_tag(:span, CustomFieldsController.helpers.show_value(value))
        end
      end
    end
    s << '</div>'
    s.html_safe
  end

end
