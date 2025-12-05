class CreateWatchlistItems < ActiveRecord::Migration[8.0]
  def change
    create_table :watchlist_items do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :tmdb_id
      t.boolean :seen

      t.timestamps
    end
  end
end
