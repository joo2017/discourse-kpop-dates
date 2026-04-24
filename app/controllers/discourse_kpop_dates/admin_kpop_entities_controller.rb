# frozen_string_literal: true

module DiscourseKpopDates
  class AdminKpopEntitiesController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    PAGE_SIZE = 50

    def index
      entities = filtered_entities
      paged_entities = entities.limit(PAGE_SIZE + 1).offset(current_page * PAGE_SIZE).to_a
      has_more = paged_entities.length > PAGE_SIZE
      paged_entities = paged_entities.first(PAGE_SIZE)

      render_json_dump(
        kpop_entities: serialize_data(paged_entities, KpopEntitySerializer, root: false),
        total: entities.count,
        has_more: has_more,
      )
    end

    def show
      render_json_dump(kpop_entity: serialize_data(find_entity, KpopEntitySerializer, root: false))
    end

    def create
      entity = KpopEntity.new(kpop_entity_params)

      if entity.save
        render_json_dump(kpop_entity: serialize_data(entity, KpopEntitySerializer, root: false))
      else
        render_json_error(entity)
      end
    end

    def import
      summary =
        if params[:file].present?
          KpopEntitiesImporter.import_file(params[:file].tempfile.path)
        else
          payload = import_payload
          KpopEntitiesImporter.import(payload)
        end

      render_json_dump(import_summary: summary)
    rescue ActionController::ParameterMissing => e
      render_json_error(e.message, status: 400)
    rescue KpopEntitiesImporter::ImportError => e
      render_json_error(e.message, status: 400)
    end

    def update
      entity = find_entity

      if entity.update(kpop_entity_params)
        render_json_dump(kpop_entity: serialize_data(entity, KpopEntitySerializer, root: false))
      else
        render_json_error(entity)
      end
    end

    def destroy
      find_entity.destroy
      render json: success_json
    end

    private

    def filtered_entities
      entities = KpopEntity.order(Arel.sql("LOWER(display_name), id"))

      if params[:q].present?
        query = "%#{params[:q].strip.downcase}%"
        entities = entities.where(
          "LOWER(display_name) LIKE :query OR LOWER(COALESCE(native_name, '')) LIKE :query OR LOWER(slug) LIKE :query",
          query: query,
        )
      end

      if params[:entity_kind].present?
        entities = entities.where(entity_kind: params[:entity_kind])
      end

      if params[:active].present?
        entities = entities.where(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
      end

      entities
    end

    def current_page
      @current_page ||= params[:page].to_i.clamp(0..)
    end

    def find_entity
      KpopEntity.find_by(id: params[:id]) || raise(Discourse::NotFound)
    end

    def import_payload
      if params[:payload_json].present?
        return JSON.parse(params[:payload_json])
      end

      payload = params[:payload]
      return payload.to_unsafe_h if payload.respond_to?(:to_unsafe_h)
      return payload if payload.is_a?(Hash)

      parsed = JSON.parse(request.raw_post.presence || "{}")
      payload = parsed["payload"] || parsed[:payload]

      if payload.respond_to?(:to_unsafe_h)
        payload.to_unsafe_h
      elsif payload.is_a?(Hash)
        payload
      else
        raise ActionController::ParameterMissing, :payload
      end
    rescue JSON::ParserError => e
      raise KpopEntitiesImporter::ImportError, "Invalid JSON payload: #{e.message}"
    end

    def kpop_entity_params
      @kpop_entity_params ||=
        begin
          permitted =
            params.permit(
              :display_name,
              :native_name,
              :slug,
              :entity_kind,
              :active,
              :birthday_month,
              :birthday_day,
              :birthday_year,
              :anniversary_month,
              :anniversary_day,
              :anniversary_year,
            )

          if permitted.key?(:active)
            permitted[:active] = ActiveModel::Type::Boolean.new.cast(permitted[:active])
          end

          permitted
        end
    end
  end
end
