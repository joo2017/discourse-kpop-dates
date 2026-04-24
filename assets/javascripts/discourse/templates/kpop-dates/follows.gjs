import { i18n } from "discourse-i18n";
import KpopEntityList from "../../components/kpop-entity-list";

export default <template>
  <h2 class="cakeday-header">{{i18n "kpop_dates.my_follows"}}</h2>

  <KpopEntityList @entities={{@model}}>
    {{i18n "kpop_dates.no_follows"}}
  </KpopEntityList>
</template>
