class Mission < ApplicationRecord
  TYPES = %w[photo video text gps].freeze

  belongs_to :game
  belongs_to :mission_category, optional: true
  has_many :submissions, dependent: :destroy

  validates :title, presence: true, length: { maximum: 140 }
  validates :points, numericality: { greater_than_or_equal_to: 0 }
  validates :bonus_points, numericality: { greater_than_or_equal_to: 0 }
  validates :mission_type, inclusion: { in: TYPES }
  validates :max_submissions_per_team, numericality: { greater_than: 0 }

  scope :by_position, -> { order(:position, :id) }

  def submissions_for(team)
    submissions.where(team: team)
  end

  def completed_by?(team)
    submissions_for(team).where(status: %w[approved pending]).exists?
  end
end
