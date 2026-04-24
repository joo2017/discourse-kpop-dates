# frozen_string_literal: true

class BackfillKpopDatesSettings < ActiveRecord::Migration[8.0]
  SETTING_MAP = {
    "cakeday_enabled" => "kpop_dates_enabled",
    "cakeday_birthday_enabled" => "kpop_dates_birthday_enabled",
  }.freeze

  def up
    return if defined?(Migration::Helpers) && Migration::Helpers.new_site?

    SETTING_MAP.each do |legacy_name, new_name|
      backfill_setting(legacy_name, new_name)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def backfill_setting(legacy_name, new_name)
    return if setting_exists?(new_name)

    legacy_value = setting_value(legacy_name)
    return if legacy_value.nil?

    create_bool_setting(new_name, legacy_value)
  end

  def setting_exists?(name)
    DB.query_single("SELECT 1 FROM site_settings WHERE name = :name", name:).first.present?
  end

  def setting_value(name)
    DB.query_single("SELECT value FROM site_settings WHERE name = :name", name:).first
  end

  def create_bool_setting(name, value)
    DB.exec(
      <<~SQL,
        INSERT INTO site_settings(name, data_type, value, created_at, updated_at)
        VALUES(:name, 5, :value, NOW(), NOW())
        ON CONFLICT (name) DO NOTHING
      SQL
      name:,
      value:,
    )
  end
end
