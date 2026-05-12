class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :join_code, null: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :status, null: false, default: "draft"
      t.boolean :allow_video, null: false, default: false
      t.boolean :show_leaderboard, null: false, default: true
      t.boolean :auto_approve, null: false, default: true

      t.timestamps
    end
    add_index :games, :join_code, unique: true
    add_index :games, :status
  end
end
