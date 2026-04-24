import EmberObject from "@ember/object";
import { trackedArray } from "@ember/reactive/collections";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";
import { i18n } from "discourse-i18n";

export default class KpopDatesFollowsRoute extends DiscourseRoute {
  @service currentUser;
  @service router;

  beforeModel() {
    if (!this.currentUser?.id) {
      this.router.transitionTo("login");
    }
  }

  async model() {
    const data = await ajax("/kpop-dates/follows.json");

    return {
      content: trackedArray((data.followed_entities || []).map((entity) => EmberObject.create(entity))),
      total: data.total_rows_follows || 0,
    };
  }

  titleToken() {
    return i18n("kpop_dates.my_follows");
  }
}
