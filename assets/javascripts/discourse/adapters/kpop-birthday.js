import KpopDatesAdapter from "discourse/plugins/discourse-kpop-dates/discourse/adapters/kpop-dates";

export default class KpopBirthdayAdapter extends KpopDatesAdapter {
  pathFor(_store, _type, findArgs) {
    return this.appendQueryParams("/kpop-dates/birthdays", findArgs);
  }
}
