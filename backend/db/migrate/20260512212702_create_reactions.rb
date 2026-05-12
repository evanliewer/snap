class CreateReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :reactions do |t|
      t.references :submission, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :kind

      t.timestamps
    end
  end
end
