# frozen_string_literal: true

RSpec.describe DiscourseKpopDates::RitualsController do
  fab!(:user)

  before do
    SiteSetting.kpop_dates_enabled = true
    SiteSetting.kpop_dates_birthday_enabled = true
  end

  describe "#today" do
    it "requires login" do
      get "/kpop-dates/ritual/today.json"

      expect(response.status).to eq(403)
    end

    it "returns today's followed birthday and anniversary items" do
      travel_to(Time.utc(2026, 4, 21, 12, 0, 0)) do
        birthday_entity =
          Fabricate(
            :kpop_entity,
            display_name: "IU",
            slug: "iu",
            entity_kind: "solo",
            birthday_month: 4,
            birthday_day: 21,
            anniversary_month: 9,
            anniversary_day: 18,
          )

        anniversary_entity =
          Fabricate(
            :kpop_entity,
            display_name: "OH MY GIRL",
            slug: "oh-my-girl",
            entity_kind: "group",
            birthday_month: nil,
            birthday_day: nil,
            anniversary_month: 4,
            anniversary_day: 21,
            anniversary_year: 2015,
          )

        DiscourseKpopDates::ArtistFollow.create!(user: user, kpop_entity: birthday_entity)
        DiscourseKpopDates::ArtistFollow.create!(user: user, kpop_entity: anniversary_entity)

        sign_in(user)
        get "/kpop-dates/ritual/today.json"

        expect(response.status).to eq(200)

        items = response.parsed_body["items"]
        expect(items.map { |item| item["slug"] }).to contain_exactly("iu", "oh-my-girl")

        birthday_item = items.find { |item| item["slug"] == "iu" }
        expect(birthday_item["event_kind"]).to eq("birthday")
        expect(birthday_item["is_dday"]).to eq(true)
        expect(birthday_item["dday_label"]).to eq("D-Day")
        expect(birthday_item["marker_emoji"]).to eq("🎂")

        anniversary_item = items.find { |item| item["slug"] == "oh-my-girl" }
        expect(anniversary_item["event_kind"]).to eq("anniversary")
        expect(anniversary_item["marker_emoji"]).to eq("🎉")
      end
    end

    it "returns birthday rituals when only birthdays are enabled" do
      travel_to(Time.utc(2026, 4, 21, 12, 0, 0)) do
        SiteSetting.kpop_dates_enabled = false
        SiteSetting.kpop_dates_birthday_enabled = true

        birthday_entity =
          Fabricate(
            :kpop_entity,
            display_name: "IU",
            slug: "iu-bday",
            entity_kind: "solo",
            birthday_month: 4,
            birthday_day: 21,
            anniversary_month: 9,
            anniversary_day: 18,
          )

        anniversary_entity =
          Fabricate(
            :kpop_entity,
            display_name: "OH MY GIRL",
            slug: "oh-my-girl-bday-only",
            entity_kind: "group",
            birthday_month: nil,
            birthday_day: nil,
            anniversary_month: 4,
            anniversary_day: 21,
            anniversary_year: 2015,
          )

        DiscourseKpopDates::ArtistFollow.create!(user: user, kpop_entity: birthday_entity)
        DiscourseKpopDates::ArtistFollow.create!(user: user, kpop_entity: anniversary_entity)

        sign_in(user)
        get "/kpop-dates/ritual/today.json"

        expect(response.status).to eq(200)
        items = response.parsed_body["items"]
        expect(items.map { |item| item["slug"] }).to eq(["iu-bday"])
      end
    end

    it "does not include a plugin-owned cheering topic url" do
      travel_to(Time.utc(2026, 4, 21, 12, 0, 0)) do
        birthday_entity =
          Fabricate(
            :kpop_entity,
            display_name: "IU",
            slug: "iu-cheer",
            entity_kind: "solo",
            birthday_month: 4,
            birthday_day: 21,
          )

        DiscourseKpopDates::ArtistFollow.create!(user: user, kpop_entity: birthday_entity)

        sign_in(user)
        get "/kpop-dates/ritual/today.json"

        expect(response.status).to eq(200)
        item = response.parsed_body["items"].find { |row| row["slug"] == "iu-cheer" }
        expect(item).not_to have_key("target_topic_url")
      end
    end
  end
end
