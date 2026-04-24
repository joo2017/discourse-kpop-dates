import { click, currentURL, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { cloneJSON } from "discourse/lib/object";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { i18n } from "discourse-i18n";
import anniversariesFixtures from "../fixtures/anniversaries";
import birthdaysFixtures from "../fixtures/birthdays";

acceptance("K-pop Dates - Sidebar with plugin disabled", function (needs) {
  needs.user();

  needs.settings({
    kpop_dates_enabled: false,
    kpop_dates_birthday_enabled: false,
    navigation_menu: "sidebar",
  });

  test("anniversaries sidebar link is hidden", async function (assert) {
    await visit("/");

    await click(
      ".sidebar-section[data-section-name='community'] .sidebar-more-section-links-details-summary"
    );

    assert
      .dom(".sidebar-section-link[data-link-name='kpop-anniversaries']")
      .doesNotExist("does not display the anniversaries link in sidebar");
  });

  test("birthdays sidebar link is hidden", async function (assert) {
    await visit("/");

    await click(
      ".sidebar-section[data-section-name='community'] .sidebar-more-section-links-details-summary"
    );

    assert
      .dom(".sidebar-section-link[data-link-name='kpop-birthdays']")
      .doesNotExist("does not display the birthdays link in sidebar");
  });
});

acceptance("K-pop Dates - Sidebar with plugin enabled", function (needs) {
  needs.user();

  needs.settings({
    kpop_dates_enabled: true,
    kpop_dates_birthday_enabled: true,
    navigation_menu: "sidebar",
  });

  needs.pretender((server, helper) => {
    server.get("/kpop-dates/anniversaries", () =>
      helper.response(cloneJSON(anniversariesFixtures))
    );
    server.get("/kpop-dates/birthdays", () =>
      helper.response(cloneJSON(birthdaysFixtures))
    );
  });

  test("clicking on anniversaries link", async function (assert) {
    await visit("/");

    await click(
      ".sidebar-section[data-section-name='community'] .sidebar-more-section-links-details-summary"
    );

    assert
      .dom(".sidebar-section-link[data-link-name='kpop-anniversaries']")
      .hasText(
        i18n("kpop_dates.anniversaries.title"),
        "displays the right text for the link"
      );

    assert
      .dom(".sidebar-section-link[data-link-name='kpop-anniversaries']")
      .hasAttribute(
        "title",
        i18n("kpop_dates.anniversaries.title"),
        "displays the right title for the link"
      );

    assert
      .dom(
        ".sidebar-section-link[data-link-name='kpop-anniversaries'] .sidebar-section-link-prefix.icon .d-icon-cake-candles"
      )
      .exists("displays the birthday-cake icon for the link");

    await click(".sidebar-section-link[data-link-name='kpop-anniversaries']");

    assert.strictEqual(
      currentURL(),
      "/kpop-dates/anniversaries/today",
      "navigates to the right page"
    );
  });

  test("clicking on birthdays link", async function (assert) {
    await visit("/");

    await click(
      ".sidebar-section[data-section-name='community'] .sidebar-more-section-links-details-summary"
    );

    assert
      .dom(".sidebar-section-link[data-link-name='kpop-birthdays']")
      .hasText(i18n("kpop_dates.birthdays.title"), "displays the right text for the link");

    assert
      .dom(".sidebar-section-link[data-link-name='kpop-birthdays']")
      .hasAttribute(
        "title",
        i18n("kpop_dates.birthdays.title"),
        "displays the right title for the link"
      );

    assert
      .dom(
        ".sidebar-section-link[data-link-name='kpop-birthdays'] .sidebar-section-link-prefix.icon .d-icon-cake-candles"
      )
      .exists("displays the birthday-cake icon for the link");

    await click(".sidebar-section-link[data-link-name='kpop-birthdays']");

    assert.strictEqual(
      currentURL(),
      "/kpop-dates/birthdays/today",
      "navigates to the right page"
    );
  });
});
