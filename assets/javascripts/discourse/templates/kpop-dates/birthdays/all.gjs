import ConditionalLoadingSpinner from "discourse/components/conditional-loading-spinner";
import LoadMore from "discourse/components/load-more";
import ComboBox from "discourse/select-kit/components/combo-box";
import { i18n } from "discourse-i18n";
import KpopEntityList from "../../../components/kpop-entity-list";

export default <template>
  <LoadMore @selector=".kpop-entity-list__item" @action={{@controller.loadMore}}>
    <div class="cakeday-months">
      <h2 class="cakeday-header">{{i18n "kpop_dates.birthdays.month.title"}}</h2>
      <ComboBox
        @content={{@controller.months}}
        @value={{@controller.month}}
        @valueAttribute="value"
        @none="kpop_dates.none"
      />
    </div>

    <ConditionalLoadingSpinner @condition={{@controller.model.loading}}>
      <KpopEntityList @entities={{@controller.model}} @isBirthday={{true}}>
        {{i18n "kpop_dates.birthdays.month.empty"}}
      </KpopEntityList>
    </ConditionalLoadingSpinner>

    <ConditionalLoadingSpinner @condition={{@controller.model.loadingMore}} />
  </LoadMore>
</template>
