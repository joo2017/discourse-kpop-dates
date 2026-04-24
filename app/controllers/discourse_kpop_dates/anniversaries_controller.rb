# frozen_string_literal: true

module DiscourseKpopDates
  class AnniversariesController < KpopDatesController
    before_action :ensure_kpop_dates_enabled
    before_action :ensure_canonical_anniversary_page_path, only: :index

    def index
      entities, total, more_path = kpop_dates_by(:anniversary)
      serialized = serialize_data(entities, PublicKpopDatesRowSerializer, root: false, event_kind: :anniversary)

      render_json_dump(
        anniversaries: serialized,
        kpop_anniversaries: serialized,
        kpop_anniversarys: serialized,
        total_rows_anniversaries: total,
        total_rows_kpop_anniversaries: total,
        total_rows_kpop_anniversarys: total,
        load_more_anniversaries: more_path,
        load_more_kpop_anniversaries: more_path,
        load_more_kpop_anniversarys: more_path,
      )
    end

    private

    def ensure_canonical_anniversary_page_path
      ensure_canonical_page_path(:anniversary)
    end

    def ensure_kpop_dates_enabled
      raise Discourse::NotFound if !SiteSetting.kpop_dates_enabled
    end
  end
end
