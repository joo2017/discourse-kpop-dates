# frozen_string_literal: true

module DiscourseKpopDates
  class KpopDatesQuery
    PAGE_SIZE = 48
    KST_TIMEZONE = "Asia/Seoul"
    Result = Struct.new(:entities, :total, keyword_init: true)

    private_class_method :new

    def self.birthdays(filter:, month:, page:)
      new(event_kind: :birthday).send(:run, filter:, month:, page:)
    end

    def self.anniversaries(filter:, month:, page:)
      new(event_kind: :anniversary).send(:run, filter:, month:, page:)
    end

    private

    attr_reader :event_kind

    def initialize(event_kind:)
      @event_kind = event_kind
    end

    def run(filter:, month:, page:)
      entities = filtered_entities(filter:, month:)
      offset = normalized_page(page) * PAGE_SIZE

      Result.new(entities: entities.slice(offset, PAGE_SIZE) || [], total: entities.size)
    end

    def filtered_entities(filter:, month:)
      target_dates = target_dates_for(filter)

      if target_dates
        date_filtered_entities(target_dates)
      else
        month_filtered_entities(normalized_month(month))
      end
    end

    def target_dates_for(filter)
      today = kst_today

      case filter.to_s
      when "today"
        [today]
      when "tomorrow"
        [today + 1.day]
      when "upcoming"
        ((today + 2.days)..(today + 8.days)).to_a
      end
    end

    def month_filtered_entities(month)
      base_scope
        .where(event_month_column => month)
        .to_a
        .sort_by { |entity| [event_month(entity), event_day(entity), normalized_name(entity)] }
    end

    def date_filtered_entities(target_dates)
      base_scope
        .to_a
        .filter_map do |entity|
          matched_date = target_dates.find { |target_date| matches_target_date?(entity, target_date) }
          [matched_date, entity] if matched_date
        end
        .sort_by { |matched_date, entity| [matched_date, normalized_name(entity)] }
        .map(&:last)
    end

    def base_scope
      scope = DiscourseKpopDates::KpopEntity.where(active: true)

      if birthday?
        scope.where(entity_kind: DiscourseKpopDates::KpopEntity.entity_kinds[:solo]).where.not(
          birthday_month: nil,
          birthday_day: nil,
        )
      else
        scope.where.not(anniversary_month: nil, anniversary_day: nil)
      end
    end

    def matches_target_date?(entity, target_date)
      observed_month, observed_day = observed_month_and_day(entity, target_date.year)

      observed_month == target_date.month && observed_day == target_date.day
    end

    def observed_month_and_day(entity, year)
      month = event_month(entity)
      day = event_day(entity)

      if month == 2 && day == 29 && !Date.gregorian_leap?(year)
        [3, 1]
      else
        [month, day]
      end
    end

    def birthday?
      event_kind == :birthday
    end

    def event_month_column
      birthday? ? :birthday_month : :anniversary_month
    end

    def event_month(entity)
      birthday? ? entity.birthday_month : entity.anniversary_month
    end

    def event_day(entity)
      birthday? ? entity.birthday_day : entity.anniversary_day
    end

    def kst_today
      Time.zone.now.in_time_zone(KST_TIMEZONE).to_date
    end

    def normalized_month(month)
      month.to_i.clamp(1..12)
    end

    def normalized_page(page)
      page.to_i.clamp(0..)
    end

    def normalized_name(entity)
      entity.display_name.downcase
    end
  end
end
