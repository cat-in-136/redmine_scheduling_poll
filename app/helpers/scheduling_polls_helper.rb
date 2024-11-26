# frozen_string_literal: true
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
    s = ''.dup
    s << '<h3>' << link_to(issue, issue_url(issue)) << '</h3>'
    s << '<div>'
    unless issue.disabled_core_fields.include?('start_date')
      s << '<p><strong>' << h(l(:field_start_date)) << '</strong></p>'
      s << content_tag(:span, format_date(issue.start_date), :class => 'start-date')
    end
    unless issue.disabled_core_fields.include?('due_date')
      s << '<p><strong>' << h(l(:field_due_date)) << '</strong></p>'
      s << content_tag(:span, format_date(issue.due_date), :class => 'due-date')
    end

    # show date-related custom field values
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

  if defined? IconsHelper # redmine >= 7.0
    include IconsHelper
    def scheduling_icon_with_label(icon_name, label_text, icon_only: false, size: 18, css_class: nil)
      label_classes = ["icon-label"]
      label_classes << "hidden" if icon_only
      plugin = 'redmine_scheduling_poll'
      sprite_icon(icon_name, size: size, css_class: css_class, plugin: plugin) + content_tag(:span, label_text, class: label_classes.join(' '))
    end
  end

end
