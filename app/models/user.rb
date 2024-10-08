class User < ApplicationRecord
  has_secure_password
  has_many :events
  has_many :participants
  has_many :messages

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || changes[:password_digest] }
  validates :name, presence: true
end

