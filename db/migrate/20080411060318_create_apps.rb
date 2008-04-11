class CreateApps < ActiveRecord::Migration
  def self.up
    create_table :apps do |t|
      t.integer :user_id
      t.string :key
      t.integer :port
      t.string :name
      t.timestamps
    end
    add_index(:apps, :user_id)
    add_index(:apps, :key)
  end

  def self.down
    drop_table :apps
  end
end
