import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

const KPOP_SIDEBAR_LINK_NAMES = ["kpop-anniversaries", "kpop-birthdays"];

function installFullPageSidebarNavigation() {
  if (document.body.dataset.kpopDatesSidebarNavInstalled) {
    return;
  }

  document.body.dataset.kpopDatesSidebarNavInstalled = "true";

  document.addEventListener(
    "click",
    (event) => {
      const target = event.target?.closest?.("a.sidebar-section-link[data-link-name]");
      if (!target) {
        return;
      }

      const linkName = target.getAttribute("data-link-name");
      if (!KPOP_SIDEBAR_LINK_NAMES.includes(linkName)) {
        return;
      }

      const href = target.getAttribute("href");
      if (!href) {
        return;
      }

      event.preventDefault();
      event.stopPropagation();
      window.location.href = href;
    },
    true,
  );
}

function initializeKpopDates(api) {
  const store = api.container.lookup("service:store");
  store.addPluralization("anniversary", "anniversaries");
  installFullPageSidebarNavigation();

  const siteSettings = api.container.lookup("service:site-settings");
  const kpopDatesEnabled = siteSettings.kpop_dates_enabled;
  const birthdayEnabled = siteSettings.kpop_dates_birthday_enabled;

  if (kpopDatesEnabled || birthdayEnabled) {
    if (kpopDatesEnabled) {
      api.addCommunitySectionLink(
        {
          name: "kpop-anniversaries",
          route: "kpop_dates.anniversaries.today",
          title: i18n("kpop_dates.anniversaries.title"),
          text: i18n("kpop_dates.anniversaries.title"),
          icon: "cake-candles",
        },
        true
      );
    }

    if (birthdayEnabled) {
      api.addCommunitySectionLink(
        {
          name: "kpop-birthdays",
          route: "kpop_dates.birthdays.today",
          title: i18n("kpop_dates.birthdays.title"),
          text: i18n("kpop_dates.birthdays.title"),
          icon: "cake-candles",
        },
        true
      );
    }
  }
}

export default {
  name: "kpop-dates",

  initialize() {
    withPluginApi((api) => initializeKpopDates(api));
  },
};
