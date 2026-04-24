# frozen_string_literal: true

module DiscourseKpopDates
  class FollowsController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :ensure_follow_login
    before_action :ensure_follow_feature_enabled

    def index
      follows =
        DiscourseKpopDates::ArtistFollow
          .includes(:kpop_entity)
          .where(user: current_user)
          .joins(:kpop_entity)
          .merge(DiscourseKpopDates::KpopEntity.where(active: true))
          .order(Arel.sql("LOWER(discourse_cakeday_kpop_entities.display_name), discourse_cakeday_kpop_entities.id"))

      entities = follows.map(&:kpop_entity)

      render_json_dump(
        followed_entity_ids: entities.map(&:id),
        followed_entities: serialize_data(entities, KpopEntitySerializer, root: false),
        total_rows_follows: entities.length,
      )
    end

    private

    def ensure_follow_login
      return if current_user.present?

      if request.format.json? || request.xhr?
        ensure_logged_in
      else
        redirect_to_login
      end
    end

    def ensure_follow_feature_enabled
      raise Discourse::NotFound if !SiteSetting.kpop_dates_enabled && !SiteSetting.kpop_dates_birthday_enabled
    end
  end
end
