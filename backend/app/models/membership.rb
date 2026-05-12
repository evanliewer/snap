class Membership < ApplicationRecord
  ROLES = %w[player judge admin].freeze

  belongs_to :user
  belongs_to :game
  belongs_to :team, optional: true

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :game_id }
  validate :team_belongs_to_game

  def admin?
    role == "admin"
  end

  def judge?
    %w[admin judge].include?(role)
  end

  private

  def team_belongs_to_game
    return unless team && team.game_id != game_id
    errors.add(:team, "must belong to the same game")
  end
end
