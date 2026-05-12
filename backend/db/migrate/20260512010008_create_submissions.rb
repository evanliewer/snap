class CreateSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :submissions do |t|
      t.references :mission, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :caption
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :status, null: false, default: "approved"
      t.integer :points_awarded, null: false, default: 0
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
      t.text :review_notes

      t.timestamps
    end
    add_index :submissions, [:mission_id, :team_id]
    add_index :submissions, :status
    add_index :submissions, :created_at
  end
end
