# frozen_string_literal: true

RSpec.describe DiscourseKpopDates::KpopEntity do
  describe "validations" do
    it "accepts a solo record with birthday and anniversary fields" do
      entity = Fabricate.build(:kpop_entity)

      expect(entity).to be_valid
    end

    it "accepts a group record with only anniversary fields" do
      entity =
        Fabricate.build(
          :kpop_entity,
          entity_kind: "group",
          birthday_month: nil,
          birthday_day: nil,
          birthday_year: nil,
        )

      expect(entity).to be_valid
    end

    it "rejects a group with birthday fields" do
      entity = Fabricate.build(:kpop_entity, entity_kind: "group")

      expect(entity).not_to be_valid
      expect(entity.errors.full_messages).not_to be_empty
    end

    it "rejects partial birthday dates" do
      entity = Fabricate.build(:kpop_entity, birthday_day: nil)

      expect(entity).not_to be_valid
      expect(entity.errors[:birthday_month]).to be_present
    end

    it "rejects anniversary years without a complete anniversary date" do
      entity =
        Fabricate.build(
          :kpop_entity,
          anniversary_month: nil,
          anniversary_day: nil,
          anniversary_year: 2015,
        )

      expect(entity).not_to be_valid
      expect(entity.errors[:anniversary_year]).to be_present
    end

    it "rejects invalid date combinations" do
      entity = Fabricate.build(:kpop_entity, birthday_month: 2, birthday_day: 30)

      expect(entity).not_to be_valid
      expect(entity.errors[:birthday_day]).to be_present
    end

    it "allows february 29 without a year using the leap-safe year" do
      entity = Fabricate.build(:kpop_entity, birthday_month: 2, birthday_day: 29, birthday_year: nil)

      expect(entity).to be_valid
    end

    it "rejects february 29 when the supplied year is not a leap year" do
      entity = Fabricate.build(:kpop_entity, birthday_month: 2, birthday_day: 29, birthday_year: 2001)

      expect(entity).not_to be_valid
      expect(entity.errors[:birthday_day]).to be_present
    end

    it "rejects slugs that are not lowercase dash-separated" do
      entity = Fabricate.build(:kpop_entity, slug: "IU")

      expect(entity).not_to be_valid
      expect(entity.errors[:slug]).to be_present
    end
  end
end
