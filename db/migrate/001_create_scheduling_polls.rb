class CreateSchedulingPolls < ActiveRecord::Migration
  def change
    create_table :scheduling_polls do |t|
      t.integer :issue_id, :null => false
      t.timestamp :create_at, :null => false
    end
  end
end
