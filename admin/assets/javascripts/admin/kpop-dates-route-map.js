export default {
  resource: "admin.adminPlugins.show",
  path: "/plugins",
  map() {
    this.route("kpopEntities", { path: "kpop-entities" }, function () {
      this.route("show", { path: "/:id" });
    });
  },
};
