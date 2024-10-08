class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.references :user, null: false, foreign_key: true
      t.references :activity, null: false, foreign_key: true
      t.text :location
      t.string :location_name
      t.datetime :start_time
      t.string :status
      t.text :description
      t.integer :max_participants

      t.timestamps
    end
  end
end
