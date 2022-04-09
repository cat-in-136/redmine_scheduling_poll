class CreateSchedulingPolls < ActiveRecord::Migration[4.2]
  def change
    create_table :scheduling_polls do |t|
      t.integer :issue_id, :null => false
      t.timestamp :created_at
    end
  end
end
