# frozen_string_literal: true

module DiscourseKpopDates
  class RitualKpopRowSerializer < ApplicationSerializer
    attributes :id,
               :slug,
               :display_name,
               :native_name,
               :entity_kind,
               :event_kind,
               :event_month,
               :event_day,
               :event_year,
               :event_label,
               :days_until_event,
               :is_dday,
               :dday_label,
               :marker_emoji

    def event_kind
      @options[:event_kind].to_s
    end

    def event_month
      birthday? ? object.birthday_month : object.anniversary_month
    end

    def event_day
      birthday? ? object.birthday_day : object.anniversary_day
    end

    def event_year
      birthday? ? object.birthday_year : object.anniversary_year
    end

    def event_label
      return "kpop_dates.events.birthday" if birthday?

      object.entity_kind == "solo" ? "kpop_dates.events.debut" : "kpop_dates.events.foundation"
    end

    def days_until_event
      @options[:days_until_event] || 0
    end

    def is_dday
      days_until_event.zero?
    end

    def dday_label
      is_dday ? "D-Day" : "D-#{days_until_event}"
    end

    def marker_emoji
      return "🎂" if birthday?

      "🎉"
    end

    private

    def birthday?
      event_kind == "birthday"
    end
  end
end
