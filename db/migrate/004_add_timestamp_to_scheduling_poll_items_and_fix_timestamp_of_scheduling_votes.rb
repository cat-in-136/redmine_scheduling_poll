class AddTimestampToSchedulingPollItemsAndFixTimestampOfSchedulingVotes < ActiveRecord::Migration[4.2]
  def change
    change_table :scheduling_poll_items do |t|
      t.timestamps :null => true
    end

    reversible do |r|
      change_table :scheduling_votes do |t|
        r.up do
          change_column :scheduling_votes, :create_at, :datetime, :null => true
          change_column :scheduling_votes, :modify_at, :datetime, :null => true
        end
        r.down do
          # do nothing
        end
      end
    end

    rename_column :scheduling_votes, :create_at, :created_at
    rename_column :scheduling_votes, :modify_at, :updated_at
  end
end
