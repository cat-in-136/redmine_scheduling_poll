class CreateSchedulingVotes < ActiveRecord::Migration
  def change
    create_table :scheduling_votes do |t|
      t.integer :user_id, :null => false
      t.integer :scheduling_poll_item_id, :null => false
      t.integer :value, :null => false
      t.timestamp :create_at
      t.timestamp :modify_at
    end
  end
end
