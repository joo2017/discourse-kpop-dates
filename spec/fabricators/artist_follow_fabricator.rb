# frozen_string_literal: true

Fabricator(:artist_follow, from: DiscourseKpopDates::ArtistFollow) do
  user
  kpop_entity
end
