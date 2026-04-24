# frozen_string_literal: true

DiscourseKpopDates::Engine.routes.draw do
  get "birthdays" => "birthdays#index"
  get "birthdays/:filter" => "birthdays#index"
  get "anniversaries" => "anniversaries#index"
  get "anniversaries/:filter" => "anniversaries#index"
  get "follows" => "follows#index"
  post "follows/:kpop_entity_id" => "artist_follows#create"
  delete "follows/:kpop_entity_id" => "artist_follows#destroy"
  get "ritual/today" => "rituals#today"
end
