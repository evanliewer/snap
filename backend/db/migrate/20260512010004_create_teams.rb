class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      t.references :game, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, null: false, default: "#4F46E5"

      t.timestamps
    end
    add_index :teams, [:game_id, :name], unique: true
  end
end
