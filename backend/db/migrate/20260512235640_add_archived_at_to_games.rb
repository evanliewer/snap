class AddArchivedAtToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :archived_at, :datetime
    add_index :games, :archived_at
  end
end
