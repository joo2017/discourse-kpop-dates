import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import discourseDebounce from "discourse/lib/debounce";
import { INPUT_DELAY } from "discourse/lib/environment";

export default class AdminPluginsShowKpopEntitiesIndexController extends Controller {
  @tracked q = "";
  @tracked entity_kind = "";
  @tracked active = "";
  @tracked loading = false;
  @tracked loadingMore = false;

  queryParams = ["q", "entity_kind", "active"];

  get hasMore() {
    return !!this.model?.hasMore;
  }

  get hasEntities() {
    return (this.model?.kpopEntities?.length || 0) > 0;
  }

  get showEmptyState() {
    return !this.loading && !this.hasEntities && !this.q;
  }

  @action
  onTextFilterChange(event) {
    this.q = event.target?.value || "";
    this.loading = true;
    discourseDebounce(this, this.resetList, INPUT_DELAY);
  }

  @action
  onEntityKindChange(event) {
    this.entity_kind = event.target?.value || "";
    this.resetList();
  }

  @action
  onActiveChange(event) {
    this.active = event.target?.value || "";
    this.resetList();
  }

  @action
  async resetList() {
    this.loading = true;

    try {
      await this.model.loadPage(0, false, {
        q: this.q,
        entity_kind: this.entity_kind,
        active: this.active,
      });
    } finally {
      this.loading = false;
    }
  }

  @action
  async loadMore() {
    if (!this.hasMore || this.loadingMore) {
      return;
    }

    this.loadingMore = true;

    try {
      await this.model.loadPage(this.model.page + 1, true, {
        q: this.q,
        entity_kind: this.entity_kind,
        active: this.active,
      });
    } finally {
      this.loadingMore = false;
    }
  }
}
