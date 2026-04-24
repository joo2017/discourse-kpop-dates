# frozen_string_literal: true

module DiscourseKpopDates
  class RitualsController < ::ApplicationController
    requires_login
    requires_plugin PLUGIN_NAME

    KST_TIMEZONE = "Asia/Seoul"

    before_action :ensure_ritual_feature_enabled

    def today
      entities = today_ritual_entities

      render_json_dump(
        items:
          entities.map do |event_kind, entity|
            RitualKpopRowSerializer.new(
              entity,
              scope: guardian,
              root: false,
              event_kind: event_kind,
              days_until_event: 0,
            ).as_json
          end,
      )
    end

    private

    def ensure_ritual_feature_enabled
      raise Discourse::NotFound if !SiteSetting.kpop_dates_enabled && !SiteSetting.kpop_dates_birthday_enabled
    end

    def today_ritual_entities
      today = Time.zone.now.in_time_zone(KST_TIMEZONE).to_date
      leap_substitute = today.month == 3 && today.day == 1 && !Date.gregorian_leap?(today.year)

      follows =
        DiscourseKpopDates::ArtistFollow
          .includes(:kpop_entity)
          .where(user: current_user)
          .joins(:kpop_entity)
          .merge(DiscourseKpopDates::KpopEntity.where(active: true))

      follows.filter_map do |follow|
        entity = follow.kpop_entity

        if SiteSetting.kpop_dates_birthday_enabled && entity.solo? && matches_event_date?(entity.birthday_month, entity.birthday_day, today, leap_substitute)
          [:birthday, entity]
        elsif SiteSetting.kpop_dates_enabled && matches_event_date?(entity.anniversary_month, entity.anniversary_day, today, leap_substitute)
          [:anniversary, entity]
        end
      end.sort_by { |event_kind, entity| [event_kind.to_s, entity.display_name.downcase] }
    end

    def matches_event_date?(month, day, today, leap_substitute)
      return false if month.blank? || day.blank?

      return true if month == today.month && day == today.day

      leap_substitute && month == 2 && day == 29
    end
  end
end
