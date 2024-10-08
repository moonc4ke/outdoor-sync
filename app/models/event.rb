class Event < ApplicationRecord
  belongs_to :user
  belongs_to :activity
  has_many :participants
  has_one :chat_room

  validates :location, presence: true
  validates :start_time, presence: true
  validates :max_participants, presence: true, numericality: { greater_than: 0 }
end

