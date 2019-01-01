class AddTimestampToSchedulingPollItemsAndFixTimestampOfSchedulingVotes < ((Rails.version > "5")? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    change_table :scheduling_poll_items do |t|
      t.timestamps :null => true
    end

    rename_column :scheduling_votes, :create_at, :created_at
    rename_column :scheduling_votes, :modify_at, :updated_at
  end
end
