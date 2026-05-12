class MissionCategory < ApplicationRecord
  belongs_to :game
  has_many :missions, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :game_id, case_sensitive: false }
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }
end
