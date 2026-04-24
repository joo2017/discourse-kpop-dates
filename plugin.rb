# frozen_string_literal: true

# name: discourse-kpop-dates
# about: Show K-pop birthdays, anniversaries, follows, and D-day rituals in Discourse.
# version: 0.3
# authors: Alan Tan
# url: https://github.com/discourse/discourse/tree/main/plugins/discourse-kpop-dates

register_asset "stylesheets/kpop-dates.scss"
register_asset "stylesheets/emoji-images.scss"

register_svg_icon "cake-candles"

add_admin_route "admin.discourse_kpop_dates.title", "discourse-kpop-dates", use_new_show_route: true

enabled_site_setting :kpop_dates_enabled

module ::DiscourseKpopDates
  PLUGIN_NAME = "discourse-kpop-dates"
end

require_relative "lib/discourse_kpop_dates/engine"

after_initialize do
  Discourse::Application.routes.append do
    mount DiscourseKpopDates::Engine, at: "/kpop-dates"

    scope "/admin/plugins/discourse-kpop-dates", constraints: AdminConstraint.new do
      get "/kpop-entities", constraints: ->(req) { !req.xhr? }, format: false,
          to: "admin/admin#index"
      get "/kpop-entities/:id", constraints: ->(req) { !req.xhr? }, format: false,
          to: "admin/admin#index"

      get "/kpop-entities" => "discourse_kpop_dates/admin_kpop_entities#index"
      post "/kpop-entities/import" => "discourse_kpop_dates/admin_kpop_entities#import"
      post "/kpop-entities" => "discourse_kpop_dates/admin_kpop_entities#create"
      get "/kpop-entities/:id" => "discourse_kpop_dates/admin_kpop_entities#show"
      put "/kpop-entities/:id" => "discourse_kpop_dates/admin_kpop_entities#update"
      patch "/kpop-entities/:id" => "discourse_kpop_dates/admin_kpop_entities#update"
      delete "/kpop-entities/:id" => "discourse_kpop_dates/admin_kpop_entities#destroy"
    end
  end

  require_relative "app/models/discourse_kpop_dates/kpop_entity"
  require_relative "app/models/discourse_kpop_dates/artist_follow"
  require_relative "app/services/discourse_kpop_dates/kpop_entities_importer"
  require_relative "app/serializers/discourse_kpop_dates/public_kpop_dates_row_serializer"
  require_relative "app/serializers/discourse_kpop_dates/ritual_kpop_row_serializer"
  require_relative "app/serializers/discourse_kpop_dates/kpop_entity_serializer"
  require_relative "app/controllers/discourse_kpop_dates/admin_kpop_entities_controller"
  require_relative "app/controllers/discourse_kpop_dates/kpop_dates_controller"
  require_relative "app/controllers/discourse_kpop_dates/follows_controller"
  require_relative "app/controllers/discourse_kpop_dates/artist_follows_controller"
  require_relative "app/controllers/discourse_kpop_dates/anniversaries_controller"
  require_relative "app/controllers/discourse_kpop_dates/birthdays_controller"
  require_relative "app/controllers/discourse_kpop_dates/rituals_controller"
  require_relative "lib/discourse_kpop_dates/kpop_dates_query"
end
