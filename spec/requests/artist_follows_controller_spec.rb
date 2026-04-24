# frozen_string_literal: true

RSpec.describe DiscourseKpopDates::ArtistFollowsController do
  fab!(:user)
  fab!(:other_user) { Fabricate(:user) }
  fab!(:entity) { Fabricate(:kpop_entity, slug: "iu", display_name: "IU") }

  before do
    SiteSetting.kpop_dates_enabled = true
    SiteSetting.kpop_dates_birthday_enabled = true
  end

  describe "#create" do
    it "creates a follow for the current user" do
      sign_in(user)

      expect {
        post "/kpop-dates/follows/#{entity.id}.json"
      }.to change { DiscourseKpopDates::ArtistFollow.count }.by(1)

      expect(response.status).to eq(200)
      expect(response.parsed_body["followed_entity_id"]).to eq(entity.id)
    end

    it "does not create duplicates" do
      DiscourseKpopDates::ArtistFollow.create!(user: user, kpop_entity: entity)
      sign_in(user)

      expect {
        post "/kpop-dates/follows/#{entity.id}.json"
      }.not_to change { DiscourseKpopDates::ArtistFollow.count }

      expect(response.status).to eq(200)
    end
  end

  describe "#destroy" do
    it "removes the current user's follow" do
      DiscourseKpopDates::ArtistFollow.create!(user: user, kpop_entity: entity)
      sign_in(user)

      expect {
        delete "/kpop-dates/follows/#{entity.id}.json"
      }.to change { DiscourseKpopDates::ArtistFollow.count }.by(-1)

      expect(response.status).to eq(200)
    end
  end

  it "works when only birthdays are enabled" do
    SiteSetting.kpop_dates_enabled = false
    SiteSetting.kpop_dates_birthday_enabled = true
    sign_in(user)

    get "/kpop-dates/follows.json"

    expect(response.status).to eq(200)
  end
end
