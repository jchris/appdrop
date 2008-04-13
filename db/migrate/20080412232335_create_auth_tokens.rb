class CreateAuthTokens < ActiveRecord::Migration
  def self.up
    create_table :auth_tokens do |t|
      t.integer :user_id
      t.integer :app_id
      t.boolean :used, :default => false
      t.string :token
      t.timestamps
    end
  end

  def self.down
    drop_table :auth_tokens
  end
end
