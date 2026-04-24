# frozen_string_literal: true

class CreateDiscourseKpopDatesKpopEntities < ActiveRecord::Migration[7.2]
  def change
    create_table :discourse_cakeday_kpop_entities do |t|
      t.string :entity_kind, null: false
      t.string :display_name, null: false
      t.string :native_name
      t.string :slug, null: false
      t.boolean :active, null: false, default: true

      t.integer :birthday_month
      t.integer :birthday_day
      t.integer :birthday_year

      t.integer :anniversary_month
      t.integer :anniversary_day
      t.integer :anniversary_year

      t.timestamps
    end

    add_index :discourse_cakeday_kpop_entities, :slug, unique: true
  end
end
