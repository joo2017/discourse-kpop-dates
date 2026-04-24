import buildKpopDatesRoute from "discourse/plugins/discourse-kpop-dates/discourse/routes/build-kpop-dates-route";

export default buildKpopDatesRoute("kpop-anniversary").extend({
  queryParams: {
    month: { refreshModel: true },
  },

  refreshQueryWithoutTransition: true,
});
