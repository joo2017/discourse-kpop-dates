import { withPluginApi } from "discourse/lib/plugin-api";

const PLUGIN_ID = "discourse-kpop-dates";

export default {
  name: "kpop-dates-admin-plugin-configuration-nav-admin",

  initialize(container) {
    const currentUser = container.lookup("service:current-user");
    if (!currentUser?.admin) {
      return;
    }

    withPluginApi((api) => {
      api.setAdminPluginIcon(PLUGIN_ID, "cake-candles");
      api.addAdminPluginConfigurationNav(PLUGIN_ID, [
        {
          label: "discourse_kpop_dates.admin.kpop_entities.title",
          route: "adminPlugins.show.kpopEntities",
        },
      ]);
    });
  },
};
