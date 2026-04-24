import Controller from "@ember/controller";
import { computed, set } from "@ember/object";
import { service } from "@ember/service";

export default class KpopDatesController extends Controller {
  @service currentUser;

  @computed("siteSettings.kpop_dates_enabled")
  get kpopDatesEnabled() {
    return this.siteSettings?.kpop_dates_enabled;
  }

  set kpopDatesEnabled(value) {
    set(this, "siteSettings.kpop_dates_enabled", value);
  }

  @computed("siteSettings.kpop_dates_birthday_enabled")
  get birthdayEnabled() {
    return this.siteSettings?.kpop_dates_birthday_enabled;
  }

  set birthdayEnabled(value) {
    set(this, "siteSettings.kpop_dates_birthday_enabled", value);
  }

  @computed("currentUser.id")
  get showFollowsTab() {
    return !!this.currentUser?.id;
  }
}
