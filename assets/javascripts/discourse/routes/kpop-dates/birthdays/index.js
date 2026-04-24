import { service } from "@ember/service";
import DiscourseRoute from "discourse/routes/discourse";

export default class KpopDatesBirthdaysIndex extends DiscourseRoute {
  @service router;

  beforeModel() {
    this.router.replaceWith("kpop_dates.birthdays.today");
  }
}
