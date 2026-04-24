# frozen_string_literal: true

Fabricator(:kpop_entity, from: DiscourseKpopDates::KpopEntity) do
  entity_kind { "solo" }
  display_name { sequence(:display_name) { |i| "Artist #{i}" } }
  native_name { nil }
  slug { sequence(:slug) { |i| "artist-#{i}" } }
  active { true }
  birthday_month { 5 }
  birthday_day { 16 }
  birthday_year { nil }
  anniversary_month { 9 }
  anniversary_day { 18 }
  anniversary_year { nil }
end
