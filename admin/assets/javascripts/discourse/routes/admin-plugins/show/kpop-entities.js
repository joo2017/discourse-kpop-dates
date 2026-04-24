import EmberObject from "@ember/object";
import { trackedArray } from "@ember/reactive/collections";
import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsShowKpopEntities extends DiscourseRoute {
  async model() {
    const model = {
      kpopEntities: trackedArray([]),
      total: 0,
      hasMore: false,
      page: 0,
      async loadPage(page, append = false, filters = {}) {
        const data = await ajax("/admin/plugins/discourse-kpop-dates/kpop-entities", {
          data: {
            page,
            q: filters.q || undefined,
            entity_kind: filters.entity_kind || undefined,
            active: filters.active || undefined,
          },
        });

        const entities = (data.kpop_entities || []).map((entity) =>
          EmberObject.create(entity)
        );

        if (append) {
          this.kpopEntities.push(...entities);
        } else {
          this.kpopEntities.splice(0, this.kpopEntities.length, ...entities);
        }

        this.total = data.total;
        this.hasMore = data.has_more;
        this.page = page;
      },
    };

    await model.loadPage(0);
    return model;
  }
}
