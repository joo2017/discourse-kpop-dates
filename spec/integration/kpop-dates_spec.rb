# frozen_string_literal: true

RSpec.describe "Anniversaries and Birthdays" do
  before do
    SiteSetting.kpop_dates_enabled = true
    SiteSetting.kpop_dates_birthday_enabled = true
  end

  describe "when not logged in" do
    it "returns the right response" do
      get "/kpop-dates/anniversaries.json"
      expect(response.status).to eq(200)
    end
  end

  describe "when logged in" do
    let(:current_user) { Fabricate(:user) }

    before { sign_in(current_user) }

    it "returns 404 when viewing anniversaries and kpop_dates_enabled is false" do
      SiteSetting.kpop_dates_enabled = false

      get "/kpop-dates/anniversaries.json"
      expect(response.status).to eq(404)
    end

    it "returns 404 when viewing birthdays and kpop_dates_birthday_enabled is false" do
      SiteSetting.kpop_dates_birthday_enabled = false

      get "/kpop-dates/birthdays.json"
      expect(response.status).to eq(404)
    end

    describe "when viewing anniversaries" do
      it "uses KST instead of the viewer timezone" do
        freeze_time(Time.utc(2026, 1, 14, 15, 30)) do
          today_entity = Fabricate(:kpop_entity, display_name: "Today Solo", slug: "today-solo", anniversary_month: 1, anniversary_day: 15)
          tomorrow_entity = Fabricate(:kpop_entity, display_name: "Tomorrow Solo", slug: "tomorrow-solo", anniversary_month: 1, anniversary_day: 16)

          get "/kpop-dates/anniversaries.json", params: { filter: "today" }

          body = response.parsed_body
          expect(body["anniversaries"].map { |entity| entity["id"] }).to eq([today_entity.id])

          get "/kpop-dates/anniversaries.json", params: { filter: "tomorrow" }

          body = response.parsed_body
          expect(body["anniversaries"].map { |entity| entity["id"] }).to eq([tomorrow_entity.id])
        end
      end

      it "maps february 29 anniversaries to march 1 in non-leap years" do
        freeze_time(Time.utc(2025, 2, 28, 16, 0)) do
          leap_day =
            Fabricate(
              :kpop_entity,
              entity_kind: "group",
              display_name: "Leap Group",
              slug: "leap-group",
              birthday_month: nil,
              birthday_day: nil,
              birthday_year: nil,
              anniversary_month: 2,
              anniversary_day: 29,
            )
          march_first =
            Fabricate(
              :kpop_entity,
              entity_kind: "group",
              display_name: "March Group",
              slug: "march-group",
              birthday_month: nil,
              birthday_day: nil,
              birthday_year: nil,
              anniversary_month: 3,
              anniversary_day: 1,
            )

          get "/kpop-dates/anniversaries.json", params: { filter: "today" }

          body = response.parsed_body
          expect(body["anniversaries"].map { |entity| entity["id"] }).to eq([leap_day.id, march_first.id])
        end
      end
    end

    describe "when viewing birthdays" do
      it "maps february 29 birthdays to march 1 in non-leap years" do
        freeze_time(Time.utc(2025, 2, 28, 16, 0)) do
          leap_day = Fabricate(:kpop_entity, display_name: "Leap Solo", slug: "leap-solo", birthday_month: 2, birthday_day: 29)
          march_first = Fabricate(:kpop_entity, display_name: "March Solo", slug: "march-solo", birthday_month: 3, birthday_day: 1)

          get "/kpop-dates/birthdays.json", params: { filter: "today" }

          body = response.parsed_body
          expect(body["birthdays"].map { |entity| entity["id"] }).to eq([leap_day.id, march_first.id])
        end
      end
    end
  end
end
