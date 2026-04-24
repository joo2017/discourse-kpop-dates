import BackButton from "discourse/components/back-button";
import KpopDatesKpopEntityForm from "../../../../../admin/components/kpop-dates-kpop-entity-form";

export default <template>
  <BackButton @route="adminPlugins.show.kpopEntities.index" />

  <div class="cakeday-kpop-entity-form-container admin-detail">
    <KpopDatesKpopEntityForm
      @model={{@model.entity}}
      @kpopEntities={{@model.kpopEntities}}
    />
  </div>
</template>
