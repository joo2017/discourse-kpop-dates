# frozen_string_literal: true

RSpec.describe DiscourseKpopDates::KpopEntitiesImporter do
  describe ".import" do
    it "creates a new solo entity from normalized JSON data" do
      summary =
        described_class.import(
          {
            source: "kpopping-calendar",
            generated_at: "2026-04-20T00:00:00Z",
            entities: [
              {
                display_name: "IU",
                native_name: "아이유",
                slug: "iu",
                entity_kind: "solo",
                active: true,
                birthday: { month: 5, day: 16, year: 1993 },
                anniversary: { month: 9, day: 18, year: 2008 },
              },
            ],
          },
        )

      expect(summary).to include(created_count: 1, updated_count: 0, skipped_count: 0, error_count: 0)

      entity = DiscourseKpopDates::KpopEntity.find_by!(slug: "iu")
      expect(entity.display_name).to eq("IU")
      expect(entity.native_name).to eq("아이유")
      expect(entity.entity_kind).to eq("solo")
      expect(entity.active).to eq(true)
      expect(entity.birthday_month).to eq(5)
      expect(entity.birthday_day).to eq(16)
      expect(entity.birthday_year).to eq(1993)
      expect(entity.anniversary_month).to eq(9)
      expect(entity.anniversary_day).to eq(18)
      expect(entity.anniversary_year).to eq(2008)
    end

    it "updates an existing entity by slug and skips a repeated import" do
      Fabricate(
        :kpop_entity,
        display_name: "IU",
        native_name: nil,
        slug: "iu",
        entity_kind: "solo",
        active: false,
        birthday_month: 5,
        birthday_day: 16,
        birthday_year: nil,
        anniversary_month: 9,
        anniversary_day: 18,
        anniversary_year: nil,
      )

      payload = {
        source: "kpopping-calendar",
        generated_at: "2026-04-20T00:00:00Z",
        entities: [
          {
            display_name: "IU Updated",
            native_name: "아이유",
            slug: "iu",
            entity_kind: "solo",
            active: true,
            birthday: { month: 5, day: 16, year: 1993 },
            anniversary: { month: 9, day: 18, year: 2008 },
          },
        ],
      }

      first_summary = described_class.import(payload)
      second_summary = described_class.import(payload)

      expect(first_summary).to include(created_count: 0, updated_count: 1, skipped_count: 0, error_count: 0)
      expect(second_summary).to include(created_count: 0, updated_count: 0, skipped_count: 1, error_count: 0)

      entity = DiscourseKpopDates::KpopEntity.find_by!(slug: "iu")
      expect(entity.display_name).to eq("IU Updated")
      expect(entity.native_name).to eq("아이유")
      expect(entity.active).to eq(true)
      expect(entity.birthday_year).to eq(1993)
      expect(entity.anniversary_year).to eq(2008)
    end

    it "imports a group with anniversary only" do
      summary =
        described_class.import(
          {
            entities: [
              {
                display_name: "BTS",
                native_name: "방탄소년단",
                slug: "bts",
                entity_kind: "group",
                active: true,
                birthday: nil,
                anniversary: { month: 6, day: 13, year: 2013 },
              },
            ],
          },
        )

      expect(summary).to include(created_count: 1, updated_count: 0, skipped_count: 0, error_count: 0)

      entity = DiscourseKpopDates::KpopEntity.find_by!(slug: "bts")
      expect(entity.entity_kind).to eq("group")
      expect(entity.birthday_month).to be_nil
      expect(entity.birthday_day).to be_nil
      expect(entity.birthday_year).to be_nil
      expect(entity.anniversary_month).to eq(6)
      expect(entity.anniversary_day).to eq(13)
      expect(entity.anniversary_year).to eq(2013)
    end

    it "records invalid group birthday input without aborting the full import" do
      summary =
        described_class.import(
          {
            entities: [
              {
                display_name: "Invalid Group",
                slug: "invalid-group",
                entity_kind: "group",
                birthday: { month: 1, day: 1, year: nil },
                anniversary: { month: 6, day: 13, year: 2013 },
              },
              {
                display_name: "Valid Solo",
                slug: "valid-solo",
                entity_kind: "solo",
                birthday: { month: 2, day: 10, year: nil },
                anniversary: nil,
              },
            ],
          },
        )

      expect(summary).to include(created_count: 1, updated_count: 0, skipped_count: 0, error_count: 1)
      expect(summary[:errors]).to eq(
        [
          {
            row: 1,
            slug: "invalid-group",
            display_name: "Invalid Group",
            messages: ["groups cannot have birthday fields"],
          },
        ],
      )
      expect(DiscourseKpopDates::KpopEntity.exists?(slug: "invalid-group")).to eq(false)
      expect(DiscourseKpopDates::KpopEntity.exists?(slug: "valid-solo")).to eq(true)
    end

    it "defaults active to true when omitted" do
      described_class.import(
        {
          entities: [
            {
              display_name: "Default Active",
              slug: "default-active",
              entity_kind: "solo",
              birthday: { month: 3, day: 12, year: nil },
              anniversary: nil,
            },
          ],
        },
      )

      expect(DiscourseKpopDates::KpopEntity.find_by!(slug: "default-active").active).to eq(true)
    end

    it "defaults active to true when explicitly null" do
      described_class.import(
        {
          entities: [
            {
              display_name: "Null Active",
              slug: "null-active",
              entity_kind: "solo",
              active: nil,
              birthday: { month: 3, day: 13, year: nil },
              anniversary: nil,
            },
          ],
        },
      )

      expect(DiscourseKpopDates::KpopEntity.find_by!(slug: "null-active").active).to eq(true)
    end

    it "records duplicate slugs in the same payload as row errors" do
      summary =
        described_class.import(
          {
            entities: [
              {
                display_name: "First IU",
                slug: "dup-iu",
                entity_kind: "solo",
                birthday: { month: 5, day: 16, year: nil },
                anniversary: nil,
              },
              {
                display_name: "Second IU",
                slug: "dup-iu",
                entity_kind: "solo",
                birthday: { month: 5, day: 17, year: nil },
                anniversary: nil,
              },
            ],
          },
        )

      expect(summary).to include(created_count: 1, updated_count: 0, skipped_count: 0, error_count: 1)
      expect(summary[:errors]).to eq(
        [
          {
            row: 2,
            slug: "dup-iu",
            display_name: "Second IU",
            messages: ["duplicate slug in import payload"],
          },
        ],
      )
    end
  end

  describe ".import_file" do
    it "raises on malformed JSON" do
      file = Tempfile.new(["invalid", ".json"])
      file.write("{")
      file.flush

      expect { described_class.import_file(file.path) }.to raise_error(
        described_class::InvalidPayloadError,
        /does not contain valid JSON/,
      )
    ensure
      file.close!
    end

    it "raises when the top level entities array is missing" do
      file = Tempfile.new(["missing-entities", ".json"])
      file.write({ source: "kpopping-calendar" }.to_json)
      file.flush

      expect { described_class.import_file(file.path) }.to raise_error(
        described_class::InvalidPayloadError,
        /must contain an 'entities' array/,
      )
    ensure
      file.close!
    end

    it "accepts a top-level array snapshot and treats it as entities" do
      file = Tempfile.new(["snapshot", ".json"])
      file.write(
        [
          {
            display_name: "Snapshot IU",
            native_name: "아이유",
            slug: "snapshot-iu",
            entity_kind: "solo",
            active: true,
            birthday: { month: 5, day: 16, year: 1993 },
            anniversary: nil,
          },
        ].to_json,
      )
      file.flush

      summary = described_class.import_file(file.path)

      expect(summary).to include(
        created_count: 1,
        updated_count: 0,
        skipped_count: 0,
        error_count: 0,
      )
      expect(DiscourseKpopDates::KpopEntity.exists?(slug: "snapshot-iu")).to eq(true)
    ensure
      file.close!
    end
  end
end
