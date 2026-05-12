class Team < ApplicationRecord
  belongs_to :game
  has_many :memberships, dependent: :nullify
  has_many :members, through: :memberships, source: :user
  has_many :submissions, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :game_id, case_sensitive: false }
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }

  def total_points
    submissions.where(status: %w[approved pending]).sum(:points_awarded)
  end
end
