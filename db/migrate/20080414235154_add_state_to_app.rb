class AddStateToApp < ActiveRecord::Migration
  def self.up
    add_column :apps, :state, :string
  end

  def self.down
    remove_column :apps, :state
  end
end
