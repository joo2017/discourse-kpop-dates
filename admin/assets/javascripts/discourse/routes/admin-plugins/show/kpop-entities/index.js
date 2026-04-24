import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowKpopEntitiesIndex extends DiscourseRoute {
  model() {
    return this.modelFor("adminPlugins.show.kpopEntities");
  }
}
