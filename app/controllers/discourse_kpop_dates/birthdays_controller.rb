# frozen_string_literal: true

module DiscourseKpopDates
  class BirthdaysController < KpopDatesController
    before_action :ensure_birthday_enabled
    before_action :ensure_canonical_birthday_page_path, only: :index

    def index
      entities, total, more_path = kpop_dates_by(:birthday)
      serialized = serialize_data(entities, PublicKpopDatesRowSerializer, root: false, event_kind: :birthday)

      render_json_dump(
        birthdays: serialized,
        kpop_birthdays: serialized,
        total_rows_birthdays: total,
        total_rows_kpop_birthdays: total,
        load_more_birthdays: more_path,
        load_more_kpop_birthdays: more_path,
      )
    end

    private

    def ensure_canonical_birthday_page_path
      ensure_canonical_page_path(:birthday)
    end

    def ensure_birthday_enabled
      raise Discourse::NotFound if !SiteSetting.kpop_dates_birthday_enabled
    end
  end
end
