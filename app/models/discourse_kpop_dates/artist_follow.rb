# frozen_string_literal: true

module DiscourseKpopDates
  class ArtistFollow < ActiveRecord::Base
    self.table_name = "discourse_cakeday_artist_follows"

    belongs_to :user
    belongs_to :kpop_entity, class_name: "DiscourseKpopDates::KpopEntity"

    validates :user_id, presence: true
    validates :kpop_entity_id, presence: true, uniqueness: { scope: :user_id }
  end
end
