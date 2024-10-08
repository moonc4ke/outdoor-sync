class Activity < ApplicationRecord
  has_many :events
  validates :name, presence: true
  validates :category, presence: true
end

