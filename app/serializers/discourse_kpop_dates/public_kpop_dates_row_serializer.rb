# frozen_string_literal: true

module DiscourseKpopDates
  class PublicKpopDatesRowSerializer < ApplicationSerializer
    attributes :id,
               :slug,
               :display_name,
               :native_name,
               :entity_kind,
               :event_kind,
               :event_month,
               :event_day,
               :event_year,
               :event_label

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

    private

    def birthday?
      event_kind == "birthday"
    end
  end
end
