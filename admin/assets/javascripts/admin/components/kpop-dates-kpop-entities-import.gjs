import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { not, or } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

export default class KpopDatesKpopEntitiesImport extends Component {
  @service toasts;

  @tracked selectedFile = null;
  @tracked importSummary = null;
  @tracked isImporting = false;

  get canImport() {
    return !!this.selectedFile && !this.isImporting;
  }

  @action
  onFileChange(event) {
    const [file] = event.target.files || [];
    this.selectedFile = file || null;
    this.importSummary = null;
  }

  @action
  async importJson() {
    if (!this.selectedFile || this.isImporting) {
      return;
    }

    this.isImporting = true;

    try {
      const payloadText = await this.selectedFile.text();
      JSON.parse(payloadText);
      const formData = new FormData();
      formData.append("file", this.selectedFile);

      const response = await fetch(
        "/admin/plugins/discourse-kpop-dates/kpop-entities/import",
        {
          method: "POST",
          headers: {
            "X-CSRF-Token": document
              .querySelector("meta[name='csrf-token']")
              ?.getAttribute("content"),
            "X-Requested-With": "XMLHttpRequest",
          },
          body: formData,
        }
      );

      const result = await response.json();

      if (!response.ok) {
        throw result;
      }

      this.importSummary = result.import_summary;

      await this.args.onImportFinished?.();

      this.toasts.success({
        data: {
          message: i18n("discourse_kpop_dates.admin.kpop_entities.import.success", {
            created: this.importSummary.created_count,
            updated: this.importSummary.updated_count,
            skipped: this.importSummary.skipped_count,
            errors: this.importSummary.error_count,
          }),
        },
        duration: "short",
      });
    } catch (error) {
      if (error instanceof SyntaxError) {
        this.importSummary = {
          created_count: 0,
          updated_count: 0,
          skipped_count: 0,
          error_count: 1,
          errors: [{ row: null, slug: null, display_name: null, messages: [i18n("discourse_kpop_dates.admin.kpop_entities.import.invalid_json")] }],
        };
      } else {
        popupAjaxError(error?.jqXHR ? error : { jqXHR: { responseJSON: error } });
      }
    } finally {
      this.isImporting = false;
    }
  }

  <template>
    <div class="cakeday-kpop-entities-import">
      <div class="cakeday-kpop-entities-import__controls">
        <input
          id="cakeday-kpop-json-import"
          type="file"
          accept="application/json,.json"
          {{on "change" this.onFileChange}}
          data-test-cakeday-import-file
        />

        <button
          type="button"
          class="btn btn-primary"
          disabled={{not this.canImport}}
          {{on "click" this.importJson}}
          data-test-cakeday-import-submit
        >
          {{i18n "discourse_kpop_dates.admin.kpop_entities.import.submit"}}
        </button>

        {{#if this.selectedFile}}
          <span class="cakeday-kpop-entities-import__filename">{{this.selectedFile.name}}</span>
        {{/if}}
      </div>

      {{#if this.importSummary}}
        <div class="cakeday-kpop-entities-import__summary" data-test-cakeday-import-summary>
          <p>
            {{i18n "discourse_kpop_dates.admin.kpop_entities.import.summary" created=this.importSummary.created_count updated=this.importSummary.updated_count skipped=this.importSummary.skipped_count errors=this.importSummary.error_count}}
          </p>

          {{#if this.importSummary.error_count}}
            <ul class="cakeday-kpop-entities-import__errors">
              {{#each this.importSummary.errors as |error|}}
                <li>
                  row={{or error.row "-"}} slug={{or error.slug "(missing)"}}: {{error.messages}}
                </li>
              {{/each}}
            </ul>
          {{/if}}
        </div>
      {{/if}}
    </div>
  </template>
}
