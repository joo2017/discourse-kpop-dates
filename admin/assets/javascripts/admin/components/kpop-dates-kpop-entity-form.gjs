import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { removeValueFromArray } from "discourse/lib/array-tools";
import { i18n } from "discourse-i18n";

export default class KpopDatesKpopEntityForm extends Component {
  @service router;
  @service dialog;
  @service toasts;

  get isNew() {
    return !this.args.model.id;
  }

  get formData() {
    const model = this.args.model;

    return {
      id: model.id,
      display_name: model.display_name,
      native_name: model.native_name,
      slug: model.slug,
      entity_kind: model.entity_kind || "solo",
      active: model.active !== false,
      birthday_month: model.birthday_month,
      birthday_day: model.birthday_day,
      birthday_year: model.birthday_year,
      anniversary_month: model.anniversary_month,
      anniversary_day: model.anniversary_day,
      anniversary_year: model.anniversary_year,
    };
  }

  isGroup(data) {
    return data.entity_kind === "group";
  }

  normalizeNumber(value) {
    if (value === "" || value === null || value === undefined) {
      return null;
    }

    const parsed = parseInt(value, 10);
    return Number.isNaN(parsed) ? null : parsed;
  }

  payloadFrom(data) {
    const payload = {
      display_name: data.display_name,
      native_name: data.native_name,
      slug: data.slug,
      entity_kind: data.entity_kind,
      active: data.active !== false,
      birthday_month: this.normalizeNumber(data.birthday_month),
      birthday_day: this.normalizeNumber(data.birthday_day),
      birthday_year: this.normalizeNumber(data.birthday_year),
      anniversary_month: this.normalizeNumber(data.anniversary_month),
      anniversary_day: this.normalizeNumber(data.anniversary_day),
      anniversary_year: this.normalizeNumber(data.anniversary_year),
    };

    if (payload.entity_kind === "group") {
      payload.birthday_month = null;
      payload.birthday_day = null;
      payload.birthday_year = null;
    }

    return payload;
  }

  @action
  onEntityKindSet(value, { set }) {
    set("entity_kind", value);

    if (value === "group") {
      set("birthday_month", null);
      set("birthday_day", null);
      set("birthday_year", null);
    }
  }

  @action
  async save(data) {
    const isNew = !data.id;
    const payload = this.payloadFrom(data);

    try {
      const result = await ajax(
        isNew
          ? "/admin/plugins/discourse-kpop-dates/kpop-entities"
          : `/admin/plugins/discourse-kpop-dates/kpop-entities/${data.id}`,
        {
          type: isNew ? "POST" : "PUT",
          data: payload,
        }
      );

      this.toasts.success({
        data: { message: i18n("saved") },
        duration: "short",
      });

      if (isNew) {
        this.args.kpopEntities.push(result.kpop_entity);
        this.router.transitionTo(
          "adminPlugins.show.kpopEntities.show",
          result.kpop_entity.id
        );
      } else {
        const existingEntity = this.args.kpopEntities.find(
          (entity) => entity.id === data.id
        );

        if (existingEntity) {
          Object.assign(existingEntity, result.kpop_entity);
        }

        Object.assign(this.args.model, result.kpop_entity);
      }
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  delete() {
    if (this.isNew) {
      this.router.transitionTo("adminPlugins.show.kpopEntities.index");
      return;
    }

    return this.dialog.confirm({
      message: i18n("discourse_kpop_dates.admin.kpop_entities.form.delete_confirm"),
      didConfirm: async () => {
        try {
          await ajax(
            `/admin/plugins/discourse-kpop-dates/kpop-entities/${this.args.model.id}`,
            { type: "DELETE" }
          );

          removeValueFromArray(
            this.args.kpopEntities,
            this.args.kpopEntities.find((entity) => entity.id === this.args.model.id)
          );
          this.router.transitionTo("adminPlugins.show.kpopEntities.index");
        } catch (error) {
          popupAjaxError(error);
        }
      },
    });
  }

  <template>
    <Form
      @onSubmit={{this.save}}
      @data={{this.formData}}
      class="cakeday-kpop-entity-form"
      as |form data|
    >
      <form.Field
        @name="display_name"
        @title={{i18n "discourse_kpop_dates.admin.kpop_entities.form.display_name"}}
        @validation="required"
        @format="large"
        @type="input"
        as |field|
      >
        <field.Control />
      </form.Field>

      <form.Field
        @name="native_name"
        @title={{i18n "discourse_kpop_dates.admin.kpop_entities.form.native_name"}}
        @format="large"
        @type="input"
        as |field|
      >
        <field.Control />
      </form.Field>

      <form.Field
        @name="slug"
        @title={{i18n "discourse_kpop_dates.admin.kpop_entities.form.slug"}}
        @validation="required"
        @format="large"
        @type="input"
        as |field|
      >
        <field.Control />
      </form.Field>

      <form.Field
        @name="entity_kind"
        @title={{i18n "discourse_kpop_dates.admin.kpop_entities.form.entity_kind"}}
        @validation="required"
        @onSet={{this.onEntityKindSet}}
        @type="select"
        as |field|
      >
        <field.Control as |select|>
          <select.Option @value="solo">{{i18n "discourse_kpop_dates.admin.kpop_entities.form.entity_kind_solo"}}</select.Option>
          <select.Option @value="group">{{i18n "discourse_kpop_dates.admin.kpop_entities.form.entity_kind_group"}}</select.Option>
        </field.Control>
      </form.Field>

      <form.Field
        @name="active"
        @title={{i18n "discourse_kpop_dates.admin.kpop_entities.form.active"}}
        @type="checkbox"
        as |field|
      >
        <field.Control />
      </form.Field>

      <form.Field
        @name="birthday_month"
        @title={{i18n "discourse_kpop_dates.admin.kpop_entities.form.birthday_month"}}
        @type="input-number"
        @disabled={{this.isGroup data}}
        as |field|
      >
        <field.Control />
      </form.Field>

      <form.Field
        @name="birthday_day"
        @title={{i18n "discourse_kpop_dates.admin.kpop_entities.form.birthday_day"}}
        @type="input-number"
        @disabled={{this.isGroup data}}
        as |field|
      >
        <field.Control />
      </form.Field>

      <form.Field
        @name="birthday_year"
        @title={{i18n "discourse_kpop_dates.admin.kpop_entities.form.birthday_year"}}
        @type="input-number"
        @disabled={{this.isGroup data}}
        as |field|
      >
        <field.Control />
      </form.Field>

      <form.Field
        @name="anniversary_month"
        @title={{i18n "discourse_kpop_dates.admin.kpop_entities.form.anniversary_month"}}
        @type="input-number"
        as |field|
      >
        <field.Control />
      </form.Field>

      <form.Field
        @name="anniversary_day"
        @title={{i18n "discourse_kpop_dates.admin.kpop_entities.form.anniversary_day"}}
        @type="input-number"
        as |field|
      >
        <field.Control />
      </form.Field>

      <form.Field
        @name="anniversary_year"
        @title={{i18n "discourse_kpop_dates.admin.kpop_entities.form.anniversary_year"}}
        @type="input-number"
        as |field|
      >
        <field.Control />
      </form.Field>

      <form.Actions>
        <form.Submit @label="save" />
        {{#unless this.isNew}}
          <form.Button
            @action={{this.delete}}
            @label="delete"
            class="btn-danger"
            data-test-cakeday-delete-entity
          />
        {{/unless}}
      </form.Actions>
    </Form>
  </template>
}
