class ChatRoom < ApplicationRecord
  belongs_to :event, optional: true
  has_many :messages
end

