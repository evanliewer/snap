class PasswordReset < ApplicationRecord
  belongs_to :user

  before_validation :generate_token, on: :create

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :live, -> { where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
    self.expires_at ||= 30.minutes.from_now
  end
end
