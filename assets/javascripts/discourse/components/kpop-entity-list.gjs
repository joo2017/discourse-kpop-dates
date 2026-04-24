import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { ajax } from "discourse/lib/ajax";
import DButton from "discourse/components/d-button";
import { i18n } from "discourse-i18n";

function eventDate(entity, { isBirthday }) {
  const month = entity.event_month;
  const day = entity.event_day;

  if (!month || !day) {
    return "";
  }

  if (!isBirthday && entity.event_year) {
    return moment({
      year: entity.event_year,
      month: month - 1,
      day,
    }).format(i18n("kpop_dates.date_formats.full_with_year"));
  }

  return moment({ year: 2000, month: month - 1, day }).format(
    i18n("kpop_dates.date_formats.short")
  );
}

function showEventLabel(entity, isBirthday) {
  return !isBirthday && !!entity.event_label;
}

function localizedEventLabel(entity) {
  return entity.event_label ? i18n(entity.event_label) : "";
}

function isFollowed(component, entityId) {
  return component.followedEntityIds.includes(entityId);
}

function isPending(component, entityId) {
  return component.pendingEntityIds.includes(entityId);
}

export default class KpopEntityList extends Component {
  @service currentUser;
  @service router;

  @tracked followedEntityIds = [];
  @tracked pendingEntityIds = [];
  @tracked followsLoaded = false;

  get entities() {
    return this.args.entities?.content || [];
  }

  get showFollowButtons() {
    return true;
  }

  isFollowed(entityId) {
    return this.followedEntityIds.includes(entityId);
  }

  isPending(entityId) {
    return this.pendingEntityIds.includes(entityId);
  }

  addPending(entityId) {
    if (!this.isPending(entityId)) {
      this.pendingEntityIds = [...this.pendingEntityIds, entityId];
    }
  }

  removePending(entityId) {
    this.pendingEntityIds = this.pendingEntityIds.filter((id) => id !== entityId);
  }

  @action
  async loadFollows() {
    if (!this.currentUser?.id || this.followsLoaded) {
      return;
    }

    try {
      const result = await ajax("/kpop-dates/follows.json");
      this.followedEntityIds = result.followed_entity_ids || [];
    } catch {
      this.followedEntityIds = [];
    } finally {
      this.followsLoaded = true;
    }
  }

  @action
  async toggleFollow(entity) {
    if (!this.currentUser?.id) {
      this.router.transitionTo("login");
      return;
    }

    if (this.isPending(entity.id)) {
      return;
    }

    this.addPending(entity.id);

    try {
      if (this.isFollowed(entity.id)) {
        await ajax(`/kpop-dates/follows/${entity.id}.json`, { type: "DELETE" });
        this.followedEntityIds = this.followedEntityIds.filter((id) => id !== entity.id);
      } else {
        await ajax(`/kpop-dates/follows/${entity.id}.json`, { type: "POST" });
        this.followedEntityIds = [...this.followedEntityIds, entity.id];
      }
    } catch {
      return;
    } finally {
      this.removePending(entity.id);
    }
  }

  <template>
  <ul class="kpop-entity-list" {{didInsert this.loadFollows}}>
    {{#each this.entities as |entity|}}
      <li class="kpop-entity-list__item">
        <div class="kpop-entity-list__name">
          {{entity.display_name}}

          {{#if entity.native_name}}
            <span class="kpop-entity-list__native-name">{{entity.native_name}}</span>
          {{/if}}
        </div>

        <div class="kpop-entity-list__date">
          {{eventDate entity isBirthday=@isBirthday}}
        </div>
        
        {{#if (showEventLabel entity @isBirthday)}}
          <div class="kpop-entity-list__type">{{localizedEventLabel entity}}</div>
        {{/if}}

        {{#if this.showFollowButtons}}
          <div class="kpop-entity-list__actions">
            <DButton
              @action={{fn this.toggleFollow entity}}
              @translatedLabel={{if
                (isFollowed this entity.id)
                (i18n "kpop_dates.following")
                (i18n "kpop_dates.follow")
              }}
              @disabled={{isPending this entity.id}}
              class="btn btn-small btn-default kpop-entity-list__follow-button"
            />
          </div>
        {{/if}}
      </li>
    {{else}}
      <li class="kpop-entity-list__empty-message"><p>{{yield}}</p></li>
    {{/each}}
  </ul>
</template>;
}
