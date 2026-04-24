# frozen_string_literal: true

module DiscourseKpopDates
  class ArtistFollowsController < ::ApplicationController
    requires_login
    requires_plugin PLUGIN_NAME

    before_action :ensure_follow_feature_enabled

    def create
      follow = current_user_follows.find_or_create_by!(kpop_entity: find_entity)
      render_json_dump(followed_entity_id: follow.kpop_entity_id)
    rescue ActiveRecord::RecordInvalid => e
      render_json_error(e.record)
    end

    def destroy
      current_user_follows.where(kpop_entity: find_entity).destroy_all
      render json: success_json
    end

    private

    def ensure_follow_feature_enabled
      raise Discourse::NotFound if !SiteSetting.kpop_dates_enabled && !SiteSetting.kpop_dates_birthday_enabled
    end

    def current_user_follows
      DiscourseKpopDates::ArtistFollow.where(user: current_user)
    end

    def find_entity
      DiscourseKpopDates::KpopEntity.find_by(id: params[:kpop_entity_id]) || raise(Discourse::NotFound)
    end
  end
end
