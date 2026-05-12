class Comment < ApplicationRecord
  belongs_to :submission
  belongs_to :user

  validates :body, presence: true, length: { maximum: 1000 }

  scope :recent, -> { order(created_at: :asc) }
end
