class AddPositionToTeams < ActiveRecord::Migration[8.1]
  def change
    add_column :teams, :position, :integer
  end
end
