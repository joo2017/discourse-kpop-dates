import EmberObject from "@ember/object";
import { trackedObject } from "@ember/reactive/collections";
import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

const EMPTY_ENTITY = {
  display_name: null,
  native_name: null,
  slug: null,
  entity_kind: "solo",
  active: true,
  birthday_month: null,
  birthday_day: null,
  birthday_year: null,
  anniversary_month: null,
  anniversary_day: null,
  anniversary_year: null,
};

export default class AdminPluginsShowKpopEntitiesShow extends DiscourseRoute {
  async model(params) {
    const parentModel = this.modelFor("adminPlugins.show.kpopEntities");

    if (params.id === "new") {
      return trackedObject({
        entity: trackedObject({ ...EMPTY_ENTITY }),
        kpopEntities: parentModel.kpopEntities,
      });
    }

    const entityId = parseInt(params.id, 10);

    if (Number.isNaN(entityId)) {
      return this.replaceWith("adminPlugins.show.kpopEntities.index");
    }

    const existingEntity = parentModel.kpopEntities.find(
      (item) => item.id === entityId
    );

    if (existingEntity) {
      return trackedObject({
        entity: trackedObject({ ...existingEntity }),
        kpopEntities: parentModel.kpopEntities,
      });
    }

    try {
      const data = await ajax(
        `/admin/plugins/discourse-kpop-dates/kpop-entities/${entityId}`
      );

      return trackedObject({
        entity: trackedObject({ ...EmberObject.create(data.kpop_entity) }),
        kpopEntities: parentModel.kpopEntities,
      });
    } catch {
      return this.replaceWith("adminPlugins.show.kpopEntities.index");
    }
  }
}
