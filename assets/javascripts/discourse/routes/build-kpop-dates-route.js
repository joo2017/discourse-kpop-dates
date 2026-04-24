import DiscourseRoute from "discourse/routes/discourse";

/** @returns {any} */
export default (storeName, filter) => {
  return class BuildKpopDatesRoute extends DiscourseRoute {
    model(params) {
      if (filter) {
        params.filter = filter;
      }

      return this.store.find(storeName, params);
    }
  };
};
