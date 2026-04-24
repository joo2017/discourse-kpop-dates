import Controller from "@ember/controller";
import { action, computed } from "@ember/object";
import { formattedKstDate } from "discourse/plugins/discourse-kpop-dates/discourse/lib/kpop-dates-date";
import { i18n } from "discourse-i18n";

export default class KpopDatesBirthdaysTodayController extends Controller {
  @computed
  get title() {
    return i18n("kpop_dates.birthdays.today.title", {
      date: formattedKstDate(),
    });
  }

  @action
  loadMore() {
    this.get("model").loadMore();
  }
}
