# frozen_string_literal: true

module DiscourseKpopDates
  class KpopDatesController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_action :setup_params

    private

    def setup_params
      @page = params[:page].to_i.clamp(0..)
      @month = params[:month].present? ? params[:month].to_i.clamp(1..12) : nil
    end

    def kpop_dates_by(event_kind)
      more_path =
        cakedays_path_for(
          event_kind,
          filter: params[:filter],
          month: @month,
          page: @page + 1,
        )

      result =
        case event_kind
        when :birthday
          DiscourseKpopDates::KpopDatesQuery.birthdays(filter: params[:filter], month: @month, page: @page)
        when :anniversary
          DiscourseKpopDates::KpopDatesQuery.anniversaries(filter: params[:filter], month: @month, page: @page)
        else
          raise ArgumentError, "Unsupported K-pop date event kind: #{event_kind.inspect}"
        end

      [result.entities, result.total, more_path]
    end

    def ensure_canonical_page_path(event_kind)
      return if request.xhr? || request.path.ends_with?(".json")

      canonical_path =
        cakedays_path_for(event_kind, filter: params[:filter], month: @month, page: params[:page])

      redirect_to canonical_path, status: :moved_permanently if canonical_path != request.fullpath
    end

    def cakedays_path_for(event_kind, filter:, month:, page: nil)
      base_path =
        if event_kind == :birthday
          "#{Discourse.base_path}/kpop-dates/birthdays"
        else
          "#{Discourse.base_path}/kpop-dates/anniversaries"
        end
      canonical_filter = canonical_filter_for(filter, month)
      normalized_page = page.present? ? page.to_i.clamp(0..) : nil

      query_params = {}
      query_params[:month] = month if canonical_filter == "all" && month.present?
      query_params[:page] = normalized_page if normalized_page.present? && normalized_page > 0

      path = canonical_filter.present? ? "#{base_path}/#{canonical_filter}" : base_path
      return path if query_params.empty?

      "#{path}?#{query_params.to_query}"
    end

    def canonical_filter_for(filter, month)
      case filter.to_s
      when "today", "tomorrow", "upcoming", "all"
        filter
      else
        month.present? ? "all" : nil
      end
    end
  end
end
