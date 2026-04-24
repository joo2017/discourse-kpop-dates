# frozen_string_literal: true

RSpec.describe DiscourseKpopDates::FollowsController do
  fab!(:user)
  fab!(:other_user) { Fabricate(:user) }
  fab!(:entity) { Fabricate(:kpop_entity, slug: "iu-follows-page", display_name: "IU") }

  before do
    SiteSetting.kpop_dates_enabled = true
    SiteSetting.kpop_dates_birthday_enabled = true
  end

  it "redirects anonymous html requests to login" do
    get "/kpop-dates/follows"

    expect(response).to redirect_to(path("/login"))
  end

  it "returns not_logged_in for anonymous json requests" do
    get "/kpop-dates/follows.json"

    expect(response.status).to eq(403)
    expect(response.parsed_body["error_type"]).to eq("not_logged_in")
  end

  it "renders html for a logged in user" do
    sign_in(user)

    get "/kpop-dates/follows"

    expect(response.status).to eq(200)
  end

  it "returns only current user's followed entities" do
    DiscourseKpopDates::ArtistFollow.create!(user: user, kpop_entity: entity)
    DiscourseKpopDates::ArtistFollow.create!(user: other_user, kpop_entity: Fabricate(:kpop_entity))

    sign_in(user)
    get "/kpop-dates/follows.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["followed_entity_ids"]).to eq([entity.id])
    expect(response.parsed_body["followed_entities"].map { |row| row["slug"] }).to eq(["iu-follows-page"])
    expect(response.parsed_body["total_rows_follows"]).to eq(1)
  end
end
