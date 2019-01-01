class CreateSchedulingPolls < ((Rails.version > "5")? ActiveRecord::Migration[4.2] : ActiveRecord::Migration)
  def change
    create_table :scheduling_polls do |t|
      t.integer :issue_id, :null => false
      t.timestamp :created_at
    end
  end
end
