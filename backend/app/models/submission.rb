class Submission < ApplicationRecord
  STATUSES = %w[pending approved rejected].freeze

  belongs_to :mission
  belongs_to :team
  belongs_to :user
  belongs_to :reviewed_by, class_name: "User", optional: true

  has_one_attached :photo
  has_one_attached :video

  validates :status, inclusion: { in: STATUSES }
  validate :enforce_team_quota, on: :create
  validate :require_media_for_mission_type

  before_validation :default_status_and_points, on: :create

  scope :recent, -> { order(created_at: :desc) }
  scope :approved_or_pending, -> { where(status: %w[approved pending]) }

  def approved?
    status == "approved"
  end

  private

  def default_status_and_points
    return if mission.nil?
    self.status ||= mission.game.auto_approve? ? "approved" : "pending"
    self.points_awarded = mission.points if points_awarded.to_i.zero? && status == "approved"
  end

  def enforce_team_quota
    return unless mission && team
    return if mission.repeatable
    existing = mission.submissions.where(team_id: team_id).where.not(id: id).where(status: %w[approved pending]).count
    if existing >= mission.max_submissions_per_team
      errors.add(:base, "Team has already submitted the maximum entries for this mission")
    end
  end

  def require_media_for_mission_type
    case mission&.mission_type
    when "photo"
      errors.add(:photo, "is required") unless photo.attached?
    when "video"
      errors.add(:video, "is required") unless video.attached? || photo.attached?
    end
  end
end
