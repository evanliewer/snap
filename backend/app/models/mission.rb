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
  validates :first_bonus_count, numericality: { greater_than_or_equal_to: 0 }
  validates :first_bonus_points, numericality: { greater_than_or_equal_to: 0 }

  scope :by_position, -> { order(:position, :id) }

  def submissions_for(team)
    submissions.where(team: team)
  end

  def completed_by?(team)
    submissions_for(team).where(status: %w[approved pending]).exists?
  end

  def available_now?(at: Time.current)
    return false if available_from && at < available_from
    return false if available_until && at > available_until
    true
  end

  # Earth-distance in meters between hotspot and a point. nil if either is missing.
  def hotspot_distance_meters(lat:, lng:)
    return nil unless hotspot_latitude && hotspot_longitude && lat && lng
    r = 6_371_000.0 # meters
    to_rad = ->(d) { d.to_f * Math::PI / 180.0 }
    dlat = to_rad.call(lat - hotspot_latitude)
    dlng = to_rad.call(lng - hotspot_longitude)
    a = Math.sin(dlat / 2)**2 +
        Math.cos(to_rad.call(hotspot_latitude)) * Math.cos(to_rad.call(lat)) *
        Math.sin(dlng / 2)**2
    2 * r * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  end

  def hotspot_required?
    hotspot_latitude.present? && hotspot_longitude.present? && hotspot_radius_m.present?
  end

  # Tier for first-bonus: returns >0 if this team would still be eligible.
  # Counts distinct prior teams that have an approved submission for this mission.
  def first_bonus_eligible?(for_team:)
    return false unless first_bonus_count.to_i.positive? && first_bonus_points.to_i.positive?
    return true if submissions_for(for_team).where(status: "approved").none?
    awarded = submissions.where(status: "approved").where.not(team_id: for_team.id).distinct.count("team_id")
    awarded < first_bonus_count.to_i
  end
end
