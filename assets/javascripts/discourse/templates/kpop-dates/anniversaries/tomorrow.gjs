import ConditionalLoadingSpinner from "discourse/components/conditional-loading-spinner";
import LoadMore from "discourse/components/load-more";
import { i18n } from "discourse-i18n";
import KpopEntityList from "../../../components/kpop-entity-list";

export default <template>
  <h2 class="cakeday-header">{{@controller.title}}</h2>

  <LoadMore @selector=".kpop-entity-list__item" @action={{@controller.loadMore}}>
    <ConditionalLoadingSpinner @condition={{@controller.model.loading}}>
      <KpopEntityList @entities={{@controller.model}}>
        {{i18n "kpop_dates.anniversaries.tomorrow.empty"}}
      </KpopEntityList>
    </ConditionalLoadingSpinner>

    <ConditionalLoadingSpinner @condition={{@controller.model.loadingMore}} />
  </LoadMore>
</template>
