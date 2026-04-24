# frozen_string_literal: true

require "json"
require "set"

module DiscourseKpopDates
  class KpopEntitiesImporter
    class ImportError < StandardError; end
    class InvalidFileError < ImportError; end
    class InvalidPayloadError < ImportError; end

    REQUIRED_ATTRIBUTES = %i[display_name slug entity_kind].freeze
    DATE_PREFIXES = %i[birthday anniversary].freeze

    def self.import(payload)
      new(payload).import
    end

    def self.import_file(file_path)
      raise InvalidFileError, "Import file path is required" if file_path.blank?

      payload = JSON.parse(File.read(file_path))
      import(payload)
    rescue Errno::ENOENT, Errno::EACCES, Errno::EISDIR => error
      raise InvalidFileError, "Could not read import file #{file_path}: #{error.message}"
    rescue JSON::ParserError => error
      raise InvalidPayloadError, "Import file #{file_path} does not contain valid JSON: #{error.message}"
    end

    def initialize(payload)
      @payload = normalize_payload(payload)
      validate_payload!
      @summary = empty_summary
      @seen_slugs = Set.new
    end

    def import
      payload[:entities].each_with_index do |raw_row, index|
        import_row(raw_row, index + 1)
      end

      summary
    end

    private

    attr_reader :payload, :summary

    def validate_payload!
      unless payload.is_a?(Hash)
        raise InvalidPayloadError, "Import payload must be a JSON object"
      end

      return if payload[:entities].is_a?(Array)

      raise InvalidPayloadError, "Import payload must contain an 'entities' array"
    end

    def import_row(raw_row, row_number)
      row = normalize_hash(raw_row)

      unless row.is_a?(Hash)
        record_error(row_number, nil, nil, ["row must be an object"])
        return
      end

      nested_shape_errors = nested_date_shape_errors(row)
      if nested_shape_errors.present?
        record_error(row_number, row[:slug], row[:display_name], nested_shape_errors)
        return
      end

      duplicate_slug_error = duplicate_slug_error_for(row)
      if duplicate_slug_error.present?
        record_error(row_number, row[:slug], row[:display_name], [duplicate_slug_error])
        return
      end

      entity = find_or_initialize_entity(row)
      was_new_record = entity.new_record?
      entity.assign_attributes(attributes_for(row))

      if !was_new_record && !entity.changed?
        summary[:skipped_count] += 1
        return
      end

      if entity.save
        summary[was_new_record ? :created_count : :updated_count] += 1
      else
        record_error(row_number, row[:slug], row[:display_name], entity.errors.full_messages)
      end
    end

    def find_or_initialize_entity(row)
      slug = row[:slug].presence

      return DiscourseKpopDates::KpopEntity.new unless slug

      DiscourseKpopDates::KpopEntity.find_or_initialize_by(slug: slug)
    end

    def attributes_for(row)
      {
        display_name: row[:display_name],
        native_name: row.key?(:native_name) ? row[:native_name] : nil,
        slug: row[:slug],
        entity_kind: row[:entity_kind],
        active: normalized_active(row),
        birthday_month: date_component(row, :birthday, :month),
        birthday_day: date_component(row, :birthday, :day),
        birthday_year: date_component(row, :birthday, :year),
        anniversary_month: date_component(row, :anniversary, :month),
        anniversary_day: date_component(row, :anniversary, :day),
        anniversary_year: date_component(row, :anniversary, :year),
      }
    end

    def nested_date_shape_errors(row)
      errors = []

      DATE_PREFIXES.each do |prefix|
        value = row[prefix]

        if !value.nil? && !value.is_a?(Hash)
          errors << "#{prefix} must be an object or null"
          next
        end

        next if value.nil?

        %i[month day year].each do |component|
          next if value[component].nil? && value[component.to_s].nil?

          begin
            normalize_integer(value[component] || value[component.to_s])
          rescue ImportError => e
            errors << "#{prefix}.#{component} #{e.message}"
          end
        end
      end

      errors
    end

    def date_component(row, prefix, component)
      date_value = row[prefix]
      return nil if date_value.nil?

      normalize_integer(date_value[component] || date_value[component.to_s])
    end

    def record_error(row_number, slug, display_name, messages)
      summary[:error_count] += 1
      summary[:errors] << {
        row: row_number,
        slug: slug,
        display_name: display_name,
        messages: Array(messages),
      }
    end

    def normalize_payload(value)
      return { entities: value } if value.is_a?(Array)

      normalize_hash(value)
    end

    def normalize_hash(value)
      return value.deep_symbolize_keys if value.is_a?(Hash)

      value
    end

    def normalize_integer(value)
      return nil if value.nil?

      Integer(value)
    rescue ArgumentError, TypeError
      raise ImportError, "must be an integer"
    end

    def normalized_active(row)
      return true if !row.key?(:active) || row[:active].nil?

      ActiveModel::Type::Boolean.new.cast(row[:active])
    end

    def duplicate_slug_error_for(row)
      slug = row[:slug].presence
      return nil if slug.blank?

      if @seen_slugs.include?(slug)
        "duplicate slug in import payload"
      else
        @seen_slugs << slug
        nil
      end
    end

    def empty_summary
      {
        created_count: 0,
        updated_count: 0,
        skipped_count: 0,
        error_count: 0,
        errors: [],
      }
    end
  end
end
