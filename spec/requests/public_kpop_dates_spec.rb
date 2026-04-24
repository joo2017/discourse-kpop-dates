# frozen_string_literal: true

RSpec.describe "Public K-pop dates endpoints" do
  fab!(:user)

  before do
    SiteSetting.kpop_dates_enabled = true
    SiteSetting.kpop_dates_birthday_enabled = true
    sign_in(user)
  end

  describe "GET /kpop-dates/birthdays.json" do
    it "returns the public birthday envelope and row shape" do
      freeze_time(Time.utc(2026, 5, 15, 15, 30)) do
        entity =
          Fabricate(
            :kpop_entity,
            display_name: "IU",
            native_name: "아이유",
            slug: "iu",
            entity_kind: "solo",
            birthday_month: 5,
            birthday_day: 16,
            birthday_year: 1993,
            anniversary_month: 9,
            anniversary_day: 18,
            anniversary_year: 2008,
          )

        get "/kpop-dates/birthdays.json", params: { filter: "today" }

        expect(response.status).to eq(200)

        body = response.parsed_body
        expect(body.keys).to contain_exactly("birthdays", "total_rows_birthdays", "load_more_birthdays")
        expect(body["total_rows_birthdays"]).to eq(1)
        expect(body["load_more_birthdays"]).to eq("/kpop-dates/birthdays/today?page=1")
        expect(body["birthdays"]).to eq(
          [
            {
              "id" => entity.id,
              "slug" => "iu",
              "display_name" => "IU",
              "native_name" => "아이유",
              "entity_kind" => "solo",
              "event_kind" => "birthday",
              "event_month" => 5,
              "event_day" => 16,
              "event_year" => 1993,
              "event_label" => "kpop_dates.events.birthday",
            },
          ],
        )
      end
    end
  end

  describe "GET /kpop-dates/anniversaries.json" do
    it "returns the public anniversary envelope and labels solo/group rows correctly" do
      freeze_time(Time.utc(2026, 6, 14, 15, 30)) do
        group =
          Fabricate(
            :kpop_entity,
            entity_kind: "group",
            display_name: "BTS",
            native_name: "방탄소년단",
            slug: "bts",
            birthday_month: nil,
            birthday_day: nil,
            birthday_year: nil,
            anniversary_month: 6,
            anniversary_day: 15,
            anniversary_year: 2013,
          )
        solo =
          Fabricate(
            :kpop_entity,
            entity_kind: "solo",
            display_name: "BoA",
            native_name: "보아",
            slug: "boa",
            anniversary_month: 6,
            anniversary_day: 15,
            anniversary_year: 2000,
          )

        get "/kpop-dates/anniversaries.json", params: { filter: "today" }

        expect(response.status).to eq(200)

        body = response.parsed_body
        expect(body.keys).to contain_exactly(
          "anniversaries",
          "total_rows_anniversaries",
          "load_more_anniversaries",
        )
        expect(body["total_rows_anniversaries"]).to eq(2)
        expect(body["load_more_anniversaries"]).to eq("/kpop-dates/anniversaries/today?page=1")
        expect(body["anniversaries"]).to eq(
          [
            {
              "id" => solo.id,
              "slug" => "boa",
              "display_name" => "BoA",
              "native_name" => "보아",
              "entity_kind" => "solo",
              "event_kind" => "anniversary",
              "event_month" => 6,
              "event_day" => 15,
              "event_year" => 2000,
              "event_label" => "kpop_dates.events.debut",
            },
            {
              "id" => group.id,
              "slug" => "bts",
              "display_name" => "BTS",
              "native_name" => "방탄소년단",
              "entity_kind" => "group",
              "event_kind" => "anniversary",
              "event_month" => 6,
              "event_day" => 15,
              "event_year" => 2013,
              "event_label" => "kpop_dates.events.foundation",
            },
          ],
        )
      end
    end

    it "preserves month browsing load-more URLs" do
      get "/kpop-dates/anniversaries.json", params: { month: 6 }

      expect(response.status).to eq(200)
      expect(response.parsed_body.keys).to contain_exactly(
        "anniversaries",
        "total_rows_anniversaries",
        "load_more_anniversaries",
      )
      expect(response.parsed_body["anniversaries"]).to eq([])
      expect(response.parsed_body["load_more_anniversaries"]).to eq("/kpop-dates/anniversaries/all?month=6&page=1")
    end
  end

end
