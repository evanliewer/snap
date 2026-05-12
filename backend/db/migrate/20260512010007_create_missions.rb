class CreateMissions < ActiveRecord::Migration[8.1]
  def change
    create_table :missions do |t|
      t.references :game, null: false, foreign_key: true
      t.references :mission_category, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :points, null: false, default: 100
      t.integer :bonus_points, null: false, default: 0
      t.string :mission_type, null: false, default: "photo"
      t.integer :position, null: false, default: 0
      t.boolean :required, null: false, default: false
      t.boolean :repeatable, null: false, default: false
      t.integer :max_submissions_per_team, null: false, default: 1
      t.boolean :requires_location, null: false, default: false

      t.timestamps
    end
    add_index :missions, [:game_id, :position]
  end
end
