class Reaction < ApplicationRecord
  KINDS = %w[heart laugh wow fire clap].freeze

  belongs_to :submission
  belongs_to :user

  validates :kind, inclusion: { in: KINDS }
  validates :user_id, uniqueness: { scope: %i[submission_id kind] }
end
