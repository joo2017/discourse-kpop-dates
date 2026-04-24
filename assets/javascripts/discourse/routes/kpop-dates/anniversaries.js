import { service } from "@ember/service";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class KpopDatesAnniversaries extends DiscourseRoute {
  @service router;

  beforeModel() {
    if (!this.siteSettings.kpop_dates_enabled) {
      this.router.transitionTo(
        "unknown",
        window.location.pathname.replace(/^\//, "")
      );
    }
  }

  titleToken() {
    return i18n("kpop_dates.anniversaries.title");
  }
}
