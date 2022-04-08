class FixTimestampOfSchedulingVotes < ActiveRecord::Migration[4.2]
  def change
    reversible do |r|
      change_table :scheduling_votes do |t|
        r.up do
          change_column :scheduling_votes, :created_at, :datetime, :null => true
          change_column :scheduling_votes, :updated_at, :datetime, :null => true
        end
        r.down do
          # do nothing
        end
      end
    end
  end
end
