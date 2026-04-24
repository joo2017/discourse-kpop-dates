# frozen_string_literal: true

module DiscourseKpopDates
  class KpopEntitySerializer < ApplicationSerializer
    attributes :id,
               :display_name,
               :native_name,
               :slug,
               :entity_kind,
               :active,
               :birthday_month,
               :birthday_day,
               :birthday_year,
               :anniversary_month,
               :anniversary_day,
               :anniversary_year
  end
end
