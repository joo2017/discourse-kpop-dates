# frozen_string_literal: true

class CreateDiscourseKpopDatesArtistFollows < ActiveRecord::Migration[7.2]
  def change
    create_table :discourse_cakeday_artist_follows do |t|
      t.bigint :user_id, null: false
      t.bigint :kpop_entity_id, null: false

      t.timestamps
    end

    add_index :discourse_cakeday_artist_follows, [:user_id, :kpop_entity_id], unique: true
    add_index :discourse_cakeday_artist_follows, [:kpop_entity_id, :user_id]
  end
end
