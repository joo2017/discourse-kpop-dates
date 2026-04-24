# frozen_string_literal: true

module DiscourseKpopDates
  class KpopEntity < ActiveRecord::Base
    self.table_name = "discourse_cakeday_kpop_entities"

    LEAP_SAFE_YEAR = 2004
    SLUG_REGEX = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
    DATE_FIELD_PREFIXES = %i[birthday anniversary].freeze

    enum :entity_kind, { solo: "solo", group: "group" }, validate: true, scopes: false

    validates :display_name, presence: true
    validates :slug, presence: true, uniqueness: true, format: { with: SLUG_REGEX }

    validate :validate_partial_dates
    validate :validate_group_birthdays

    private

    def validate_partial_dates
      DATE_FIELD_PREFIXES.each { |prefix| validate_date_fields(prefix) }
    end

    def validate_group_birthdays
      return unless group?
      return if birthday_month.blank? && birthday_day.blank? && birthday_year.blank?

      errors.add(:base, "groups cannot have birthday fields")
    end

    def validate_date_fields(prefix)
      month = public_send("#{prefix}_month")
      day = public_send("#{prefix}_day")
      year = public_send("#{prefix}_year")

      if month.present? != day.present?
        errors.add("#{prefix}_month".to_sym, "must be present with #{prefix}_day")
      end

      if year.present? && (month.blank? || day.blank?)
        errors.add("#{prefix}_year".to_sym, "requires #{prefix}_month and #{prefix}_day")
      end

      return if month.blank? || day.blank?

      validation_year = year || LEAP_SAFE_YEAR
      return if Date.valid_date?(validation_year, month, day)

      errors.add("#{prefix}_day".to_sym, "is not a valid date")
    end
  end
end
