class Game < ApplicationRecord
  STATUSES = %w[draft scheduled active ended archived].freeze

  belongs_to :owner, class_name: "User"
  has_many :memberships, dependent: :destroy
  has_many :players, through: :memberships, source: :user
  has_many :teams, dependent: :destroy
  has_many :mission_categories, -> { order(:position) }, dependent: :destroy
  has_many :missions, -> { order(:position) }, dependent: :destroy
  has_many :submissions, through: :missions
  has_one_attached :cover_image

  before_validation :generate_join_code, on: :create
  before_validation :normalize_status

  validates :title, presence: true, length: { maximum: 120 }
  validates :join_code, presence: true, uniqueness: { case_sensitive: false },
            format: { with: /\A[A-Z0-9]{4,8}\z/ }
  validates :status, inclusion: { in: STATUSES }

  scope :live, -> { where(status: %w[scheduled active]) }
  scope :unarchived, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current, status: "archived")
  end

  def unarchive!
    update!(archived_at: nil, status: status == "archived" ? "draft" : status)
  end

  def active?
    status == "active"
  end

  def admin?(user)
    return false unless user
    return true if owner_id == user.id
    memberships.exists?(user_id: user.id, role: %w[admin judge])
  end

  def membership_for(user)
    return nil unless user
    memberships.find_by(user_id: user.id)
  end

  def leaderboard
    teams
      .joins("LEFT JOIN submissions ON submissions.team_id = teams.id AND submissions.status IN ('approved','pending')")
      .group("teams.id")
      .select(
        "teams.*, " \
        "COALESCE(SUM(submissions.points_awarded),0) AS total_points, " \
        "COUNT(DISTINCT submissions.id) AS submission_count, " \
        "MAX(submissions.created_at) AS last_submission_at"
      )
      # Tiebreakers: more points → more submissions → earliest last submission → name
      .order(Arel.sql("total_points DESC, submission_count DESC, last_submission_at ASC NULLS LAST, teams.name ASC"))
  end

  private

  def generate_join_code
    return if join_code.present?
    loop do
      candidate = SecureRandom.alphanumeric(6).upcase
      break self.join_code = candidate unless Game.exists?(join_code: candidate)
    end
  end

  def normalize_status
    self.status = "draft" if status.blank?
  end
end
