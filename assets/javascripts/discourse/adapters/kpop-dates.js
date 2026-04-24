import RESTAdapter from "discourse/adapters/rest";

export default class KpopDatesAdapter extends RESTAdapter {
  basePath() {
    return "/kpop-dates/";
  }
}
