class AddTimingAndHotspotToMissions < ActiveRecord::Migration[8.1]
  def change
    add_column :missions, :available_from, :datetime
    add_column :missions, :available_until, :datetime
    add_column :missions, :hotspot_latitude, :decimal, precision: 10, scale: 6
    add_column :missions, :hotspot_longitude, :decimal, precision: 10, scale: 6
    add_column :missions, :hotspot_radius_m, :integer
    add_column :missions, :first_bonus_count, :integer, default: 0, null: false
    add_column :missions, :first_bonus_points, :integer, default: 0, null: false
  end
end
