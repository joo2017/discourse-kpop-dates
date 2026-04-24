import { on } from "@ember/modifier";
import { LinkTo } from "@ember/routing";
import ConditionalLoadingSpinner from "discourse/components/conditional-loading-spinner";
import DButton from "discourse/components/d-button";
import DPageSubheader from "discourse/components/d-page-subheader";
import { i18n } from "discourse-i18n";
import KpopDatesKpopEntitiesImport from "../../../../../admin/components/kpop-dates-kpop-entities-import";

const KpopEntitiesIndex = <template>
  <div class="discourse-kpop-dates__kpop-entities admin-detail">
    <DPageSubheader @titleLabel={{i18n "discourse_kpop_dates.admin.kpop_entities.title"}}>
      <:actions>
        <LinkTo
          @route="adminPlugins.show.kpopEntities.show"
          @model="new"
          class="btn btn-primary"
          data-test-cakeday-new-entity
        >
          {{i18n "discourse_kpop_dates.admin.kpop_entities.new"}}
        </LinkTo>
      </:actions>
    </DPageSubheader>

    <KpopDatesKpopEntitiesImport @onImportFinished={{@controller.resetList}} />

    <input
      type="search"
      value={{@controller.q}}
      placeholder={{i18n "discourse_kpop_dates.admin.kpop_entities.filters.search"}}
      {{on "input" @controller.onTextFilterChange}}
      data-test-cakeday-search-filter
    />

    <select
      class="select-kit"
      value={{@controller.entity_kind}}
      {{on "change" @controller.onEntityKindChange}}
      data-test-cakeday-kind-filter
    >
      <option value="">{{i18n "discourse_kpop_dates.admin.kpop_entities.filters.all_kinds"}}</option>
      <option value="solo">{{i18n "discourse_kpop_dates.admin.kpop_entities.form.entity_kind_solo"}}</option>
      <option value="group">{{i18n "discourse_kpop_dates.admin.kpop_entities.form.entity_kind_group"}}</option>
    </select>

    <select
      class="select-kit"
      value={{@controller.active}}
      {{on "change" @controller.onActiveChange}}
      data-test-cakeday-active-filter
    >
      <option value="">{{i18n "discourse_kpop_dates.admin.kpop_entities.filters.all_states"}}</option>
      <option value="true">{{i18n "yes_value"}}</option>
      <option value="false">{{i18n "no_value"}}</option>
    </select>

    <ConditionalLoadingSpinner @condition={{@controller.loading}} />

    {{#if @controller.hasEntities}}
        <table class="d-table cakeday-admin-entities-table">
          <thead class="d-table__header">
            <tr>
              <th>{{i18n "discourse_kpop_dates.admin.kpop_entities.columns.name"}}</th>
              <th>{{i18n "discourse_kpop_dates.admin.kpop_entities.columns.kind"}}</th>
              <th>{{i18n "discourse_kpop_dates.admin.kpop_entities.columns.active"}}</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {{#each @model.kpopEntities as |entity|}}
              <tr class="d-table__row" data-cakeday-entity-id={{entity.id}}>
                <td class="d-table__cell --overview">{{entity.display_name}}</td>
                <td class="d-table__cell --overview">{{entity.entity_kind}}</td>
                <td class="d-table__cell --overview">
                  {{if entity.active (i18n "yes_value") (i18n "no_value")}}
                </td>
                <td class="d-table__cell --controls">
                  <LinkTo
                    @route="adminPlugins.show.kpopEntities.show"
                    @model={{entity.id}}
                    class="btn btn-small btn-default"
                  >
                    {{i18n "discourse_kpop_dates.admin.kpop_entities.edit"}}
                  </LinkTo>
                </td>
              </tr>
            {{/each}}
          </tbody>
        </table>

        <ConditionalLoadingSpinner @condition={{@controller.loadingMore}} />

        {{#if @controller.hasMore}}
          <DButton
            @translatedLabel="load_more"
            @action={{@controller.loadMore}}
            class="btn btn-default cakeday-admin-load-more"
            data-test-cakeday-load-more
          />
        {{/if}}
    {{else}}
      {{#unless @controller.loading}}
      <div class="admin-config-area-empty-list">
        {{i18n "discourse_kpop_dates.admin.kpop_entities.empty"}}
      </div>
      {{/unless}}
    {{/if}}
  </div>
</template>;

export default KpopEntitiesIndex;
