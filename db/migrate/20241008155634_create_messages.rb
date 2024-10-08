class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :user, null: false, foreign_key: true
      t.references :chat_room, polymorphic: true, null: false
      t.text :content

      t.timestamps
    end
  end
end
