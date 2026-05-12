class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :games_as_player, through: :memberships, source: :game
  has_many :owned_games, class_name: "Game", foreign_key: :owner_id, dependent: :destroy
  has_many :submissions, dependent: :destroy

  before_validation :normalize_email

  validates :email_address, presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  def admin?
    admin
  end

  private

  def normalize_email
    self.email_address = email_address.to_s.downcase.strip
  end
end
