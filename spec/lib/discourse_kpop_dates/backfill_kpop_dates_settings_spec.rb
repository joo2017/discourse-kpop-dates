# frozen_string_literal: true

RSpec.describe BackfillKpopDatesSettings do
  let(:connection) { ActiveRecord::Base.connection }

  def site_setting_value(name)
    connection.select_value("SELECT value FROM site_settings WHERE name = #{connection.quote(name)}")
  end

  def insert_bool_setting(name, value)
    connection.exec_insert(
      "INSERT INTO site_settings(name, data_type, value, created_at, updated_at) VALUES(?, 5, ?, NOW(), NOW())",
      "SQL",
      [
        ActiveRecord::Relation::QueryAttribute.new("name", name, ActiveRecord::Type::String.new),
        ActiveRecord::Relation::QueryAttribute.new("value", value, ActiveRecord::Type::String.new),
      ],
    )
  end

  before do
    connection.execute("DELETE FROM site_settings WHERE name IN ('cakeday_enabled', 'cakeday_birthday_enabled', 'kpop_dates_enabled', 'kpop_dates_birthday_enabled')")
  end

  after do
    connection.execute("DELETE FROM site_settings WHERE name IN ('cakeday_enabled', 'cakeday_birthday_enabled', 'kpop_dates_enabled', 'kpop_dates_birthday_enabled')")
  end

  it "copies legacy settings when destination settings are absent" do
    insert_bool_setting("cakeday_enabled", "t")
    insert_bool_setting("cakeday_birthday_enabled", "f")

    described_class.new.up

    expect(site_setting_value("kpop_dates_enabled")).to eq("t")
    expect(site_setting_value("kpop_dates_birthday_enabled")).to eq("f")
  end

  it "does not overwrite existing destination settings" do
    insert_bool_setting("cakeday_enabled", "t")
    insert_bool_setting("kpop_dates_enabled", "f")

    described_class.new.up

    expect(site_setting_value("kpop_dates_enabled")).to eq("f")
  end

  it "does nothing when legacy settings are absent" do
    described_class.new.up

    expect(site_setting_value("kpop_dates_enabled")).to be_nil
    expect(site_setting_value("kpop_dates_birthday_enabled")).to be_nil
  end
end
