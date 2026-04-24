# frozen_string_literal: true

RSpec.describe DiscourseKpopDates::KpopDatesQuery do
  describe ".birthdays" do
    it "uses KST today/tomorrow/upcoming semantics" do
      freeze_time(Time.utc(2026, 1, 14, 15, 30)) do
        today_entity =
          Fabricate(:kpop_entity, display_name: "Today Solo", slug: "today-solo", birthday_month: 1, birthday_day: 15)
        tomorrow_entity =
          Fabricate(
            :kpop_entity,
            display_name: "Tomorrow Solo",
            slug: "tomorrow-solo",
            birthday_month: 1,
            birthday_day: 16,
          )
        upcoming_entity =
          Fabricate(
            :kpop_entity,
            display_name: "Upcoming Solo",
            slug: "upcoming-solo",
            birthday_month: 1,
            birthday_day: 20,
          )

        today_result = described_class.birthdays(filter: "today", month: nil, page: 0)
        tomorrow_result = described_class.birthdays(filter: "tomorrow", month: nil, page: 0)
        upcoming_result = described_class.birthdays(filter: "upcoming", month: nil, page: 0)

        expect(today_result.entities).to eq([today_entity])
        expect(tomorrow_result.entities).to eq([tomorrow_entity])
        expect(upcoming_result.entities).to eq([upcoming_entity])
      end
    end

    it "excludes inactive records and groups from birthdays" do
      freeze_time(Time.utc(2026, 1, 14, 15, 30)) do
        expected =
          Fabricate(:kpop_entity, display_name: "Active Solo", slug: "active-solo", birthday_month: 1, birthday_day: 15)
        Fabricate(
          :kpop_entity,
          display_name: "Inactive Solo",
          slug: "inactive-solo",
          active: false,
          birthday_month: 1,
          birthday_day: 15,
        )

        invalid_group = Fabricate(:kpop_entity, slug: "invalid-group")
        invalid_group.update_columns(entity_kind: "group", birthday_month: 1, birthday_day: 15)

        result = described_class.birthdays(filter: "today", month: nil, page: 0)

        expect(result.entities).to eq([expected])
      end
    end

    it "preserves the page size contract and same-day alphabetical ordering" do
      50.times do |index|
        Fabricate(
          :kpop_entity,
          display_name: format("Artist %02d", index),
          slug: format("artist-%02d", index),
          birthday_month: 5,
          birthday_day: 16,
        )
      end

      first_page = described_class.birthdays(filter: nil, month: 5, page: 0)
      second_page = described_class.birthdays(filter: nil, month: 5, page: 1)

      expect(first_page.total).to eq(50)
      expect(first_page.entities.length).to eq(48)
      expect(first_page.entities.map(&:display_name).first(3)).to eq(["Artist 00", "Artist 01", "Artist 02"])
      expect(second_page.entities.map(&:display_name)).to eq(["Artist 48", "Artist 49"])
    end

    it "maps february 29 birthdays to march 1 in non-leap years" do
      freeze_time(Time.utc(2025, 2, 28, 16, 0)) do
        leap_day =
          Fabricate(:kpop_entity, display_name: "Leap Day Solo", slug: "leap-day-solo", birthday_month: 2, birthday_day: 29)
        march_first =
          Fabricate(:kpop_entity, display_name: "March First Solo", slug: "march-first-solo", birthday_month: 3, birthday_day: 1)

        result = described_class.birthdays(filter: "today", month: nil, page: 0)

        expect(result.entities).to eq([leap_day, march_first])
      end
    end
  end

  describe ".anniversaries" do
    it "includes solo and group anniversaries while excluding inactive records" do
      freeze_time(Time.utc(2026, 6, 14, 15, 30)) do
        group =
          Fabricate(
            :kpop_entity,
            entity_kind: "group",
            display_name: "Alpha Group",
            slug: "alpha-group",
            birthday_month: nil,
            birthday_day: nil,
            birthday_year: nil,
            anniversary_month: 6,
            anniversary_day: 15,
          )
        solo =
          Fabricate(
            :kpop_entity,
            display_name: "Beta Solo",
            slug: "beta-solo",
            anniversary_month: 6,
            anniversary_day: 15,
          )
        Fabricate(
          :kpop_entity,
          display_name: "Inactive Group",
          slug: "inactive-group",
          entity_kind: "group",
          active: false,
          birthday_month: nil,
          birthday_day: nil,
          birthday_year: nil,
          anniversary_month: 6,
          anniversary_day: 15,
        )

        result = described_class.anniversaries(filter: "today", month: nil, page: 0)

        expect(result.entities).to eq([group, solo])
      end
    end

    it "maps february 29 anniversaries to march 1 in non-leap years" do
      freeze_time(Time.utc(2025, 2, 28, 16, 0)) do
        leap_day =
          Fabricate(
            :kpop_entity,
            entity_kind: "group",
            display_name: "Alpha Group",
            slug: "alpha-group-anniversary",
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
            display_name: "Beta Group",
            slug: "beta-group-anniversary",
            birthday_month: nil,
            birthday_day: nil,
            birthday_year: nil,
            anniversary_month: 3,
            anniversary_day: 1,
          )

        result = described_class.anniversaries(filter: "today", month: nil, page: 0)

        expect(result.entities).to eq([leap_day, march_first])
      end
    end
  end
end
