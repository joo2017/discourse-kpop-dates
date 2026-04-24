import { LinkTo } from "@ember/routing";
import { i18n } from "discourse-i18n";

export default <template>
  <div class="anniversaries">
    <ul class="nav-pills">
      <li>
        <LinkTo @route="kpop_dates.anniversaries.today">
          {{i18n "kpop_dates.today"}}
        </LinkTo>
      </li>

      <li>
        <LinkTo @route="kpop_dates.anniversaries.tomorrow">
          {{i18n "kpop_dates.tomorrow"}}
        </LinkTo>
      </li>

      <li>
        <LinkTo @route="kpop_dates.anniversaries.upcoming">
          {{i18n "kpop_dates.upcoming"}}
        </LinkTo>
      </li>

      <li>
        <LinkTo @route="kpop_dates.anniversaries.all">
          {{i18n "kpop_dates.all"}}
        </LinkTo>
      </li>
    </ul>

    {{outlet}}
  </div>
</template>
