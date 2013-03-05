class ChangeCurrentDayTypeToDatetimeOnWorkRecordsTable < ActiveRecord::Migration
  def up
    change_column :work_records, :current_day, :datetime
  end

  def down
    change_column :work_records, :current_day, :integer
  end
end
