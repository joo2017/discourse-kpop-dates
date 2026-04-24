import { LinkTo } from "@ember/routing";
import { i18n } from "discourse-i18n";

export default <template>
  <div class="container cakeday">
    <ul class="nav-pills">
      {{#if @controller.showFollowsTab}}
        <li class="nav-item-follows">
          <LinkTo @route="kpop_dates.follows">
            {{i18n "kpop_dates.my_follows"}}
          </LinkTo>
        </li>
      {{/if}}

      {{#if @controller.kpopDatesEnabled}}
        <li class="nav-item-anniversaries">
          <LinkTo @route="kpop_dates.anniversaries">
            {{i18n "kpop_dates.anniversaries.title"}}
          </LinkTo>
        </li>
      {{/if}}

      {{#if @controller.birthdayEnabled}}
        <li class="nav-item-birthdays">
          <LinkTo @route="kpop_dates.birthdays">
            {{i18n "kpop_dates.birthdays.title"}}
          </LinkTo>
        </li>
      {{/if}}
    </ul>

    {{outlet}}
  </div>
</template>
