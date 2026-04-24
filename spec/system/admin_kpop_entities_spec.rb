# frozen_string_literal: true

RSpec.describe "Admin K-pop Entities" do
  fab!(:admin)

  let(:form) { PageObjects::Components::FormKit.new(".cakeday-kpop-entity-form") }
  let(:dialog) { PageObjects::Components::Dialog.new }
  let(:toasts) { PageObjects::Components::Toasts.new }

  context "when plugin is enabled" do
    before do
      enable_current_plugin
      sign_in(admin)
    end

    it "supports the full k-pop entity lifecycle" do
      page.visit "/admin/plugins/discourse-kpop-dates/kpop-entities/new"

      expect(page).to have_no_css(".alert-error")
      expect(page).to have_current_path(%r{/admin/plugins/discourse-kpop-dates/kpop-entities/new})

      form.field("display_name").fill_in("IU")
      form.field("native_name").fill_in("아이유")
      form.field("slug").fill_in("iu")
      form.field("birthday_month").fill_in("5")
      form.field("birthday_day").fill_in("16")
      form.field("birthday_year").fill_in("1993")
      form.field("anniversary_month").fill_in("9")
      form.field("anniversary_day").fill_in("18")
      form.field("anniversary_year").fill_in("2008")

      form.submit

      expect(toasts).to have_success(I18n.t("js.saved"))

      entity = DiscourseKpopDates::KpopEntity.find_by(slug: "iu")
      expect(entity).to have_attributes(
        display_name: "IU",
        native_name: "아이유",
        entity_kind: "solo",
        birthday_month: 5,
        birthday_day: 16,
        birthday_year: 1993,
      )

      find("a.back-button").click

      expect(page).to have_css(".cakeday-admin-entities-table tr.d-table__row", text: "IU")

      find(".cakeday-admin-entities-table tr.d-table__row", text: "IU").find(".btn").click

      form.field("slug").fill_in("lee-ji-eun")
      form.field("entity_kind").select("group")

      expect(form.field("birthday_month")).to be_disabled
      expect(form.field("birthday_day")).to be_disabled
      expect(form.field("birthday_year")).to be_disabled
      expect(form.field("birthday_month").value).to eq("")
      expect(form.field("birthday_day").value).to eq("")
      expect(form.field("birthday_year").value).to eq("")

      form.submit

      expect(toasts).to have_success(I18n.t("js.saved"))

      expect(entity.reload).to have_attributes(
        slug: "lee-ji-eun",
        entity_kind: "group",
        birthday_month: nil,
        birthday_day: nil,
        birthday_year: nil,
      )

      find("[data-test-cakeday-delete-entity]").click

      expect(dialog).to be_open
      dialog.click_yes

      expect(page).to have_current_path(%r{/admin/plugins/discourse-kpop-dates/kpop-entities$})
      expect(page).to have_no_css(".cakeday-admin-entities-table tr.d-table__row", text: "IU")
      expect(DiscourseKpopDates::KpopEntity.exists?(entity.id)).to eq(false)
    end

    it "shows the JSON import controls on the admin index page" do
      page.visit "/admin/plugins/discourse-kpop-dates/kpop-entities"

      expect(page).to have_css("[data-test-cakeday-import-file]", visible: false, wait: 10)
      expect(page).to have_css("[data-test-cakeday-import-submit]", wait: 10)
      expect(page).to have_text(I18n.t("js.discourse_kpop_dates.admin.kpop_entities.import.submit"))
    end
  end

  context "when plugin is toggled on from the plugins list" do
    before do
      SiteSetting.kpop_dates_enabled = true
      sign_in(admin)
    end

    it "shows the K-pop Entities nav tab after enabling and clicking into the plugin" do
      page.visit "/admin/plugins/discourse-kpop-dates/settings"

      expect(page).to have_css(
        ".admin-plugin-config-page__top-nav-item",
        text: "K-pop Entities",
      )
    end
  end
end
