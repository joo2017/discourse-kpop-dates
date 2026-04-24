# frozen_string_literal: true

RSpec.describe "Public K-pop dates pages" do
  before do
    enable_current_plugin
    SiteSetting.kpop_dates_enabled = true
    SiteSetting.kpop_dates_birthday_enabled = true
  end

  it "renders birthdays with a KST-backed heading and no user affordances",
     time: Time.utc(2026, 1, 14, 15, 30) do
    Fabricate(
      :kpop_entity,
      display_name: "IU",
      native_name: "아이유",
      slug: "iu",
      entity_kind: "solo",
      birthday_month: 1,
      birthday_day: 15,
      birthday_year: 1993,
    )

    visit "/kpop-dates/birthdays/today"

    expect(page).to have_css(
      ".cakeday-header",
      text: I18n.t("js.birthdays.today.title", date: "January 15th"),
    )
    expect(page).to have_css(".load-more-sentinel", visible: :all)
    expect(page).to have_css(".kpop-entity-list")
    expect(page).to have_css(".kpop-entity-list__item", count: 1)
    expect(page).to have_css(".kpop-entity-list__name", text: "IU")
    expect(page).to have_css(".kpop-entity-list__native-name", text: "아이유")
    expect(page).to have_css(".kpop-entity-list__date", text: "Jan 15")
    expect(page).to have_no_css(".kpop-entity-list__date", text: "1993")
    expect(page).to have_no_css(".kpop-entity-list__type")

    within(".cakeday") do
      expect(page).to have_no_css(".user-info")
      expect(page).to have_no_css(".user-info-list")
      expect(page).to have_no_css(".user-image")
      expect(page).to have_no_css("[data-user-card]")
      expect(page).to have_no_css(".kpop-entity-list__item a")
    end
  end

  it "renders anniversaries with event labels and preserved shell",
     time: Time.utc(2026, 1, 15, 3, 0) do
    Fabricate(
      :kpop_entity,
      display_name: "BLACKPINK",
      native_name: "블랙핑크",
      slug: "blackpink",
      entity_kind: "group",
      birthday_month: nil,
      birthday_day: nil,
      birthday_year: nil,
      anniversary_month: 1,
      anniversary_day: 15,
      anniversary_year: 2016,
    )

    visit "/kpop-dates/anniversaries/today"

    expect(page).to have_css(
      ".cakeday-header",
      text: I18n.t("js.anniversaries.today.title", date: "January 15th"),
    )
    expect(page).to have_css(".load-more-sentinel", visible: :all)
    expect(page).to have_css(".kpop-entity-list")
    expect(page).to have_css(".kpop-entity-list__item", count: 1)
    expect(page).to have_css(".kpop-entity-list__name", text: "BLACKPINK")
    expect(page).to have_css(".kpop-entity-list__native-name", text: "블랙핑크")
    expect(page).to have_css(".kpop-entity-list__date", text: "Jan 15, 2016")
    expect(page).to have_css(
      ".kpop-entity-list__type",
      text: I18n.t("js.kpop_dates.events.foundation"),
    )

    within(".cakeday") do
      expect(page).to have_no_css(".user-info")
      expect(page).to have_no_css(".user-info-list")
      expect(page).to have_no_css(".user-image")
      expect(page).to have_no_css("[data-user-card]")
      expect(page).to have_no_css(".kpop-entity-list__item a")
    end
  end

  it "renders the upcoming birthdays range using the exact KST query window",
     time: Time.utc(2026, 1, 14, 15, 30) do
    Fabricate(
      :kpop_entity,
      display_name: "Start Window Artist",
      slug: "start-window-artist",
      birthday_month: 1,
      birthday_day: 17,
    )
    Fabricate(
      :kpop_entity,
      display_name: "End Window Artist",
      slug: "end-window-artist",
      birthday_month: 1,
      birthday_day: 23,
    )

    visit "/kpop-dates/birthdays/upcoming"

    expect(page).to have_css(
      ".cakeday-header",
      text: I18n.t(
        "js.birthdays.upcoming.title",
        start_date: "January 17th",
        end_date: "January 23rd",
      ),
    )
    expect(page).to have_css(".kpop-entity-list__item", count: 2)
    expect(page).to have_css(".kpop-entity-list__name", text: "Start Window Artist")
    expect(page).to have_css(".kpop-entity-list__name", text: "End Window Artist")
  end
end
