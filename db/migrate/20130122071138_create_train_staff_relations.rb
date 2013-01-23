class CreateTrainStaffRelations < ActiveRecord::Migration
  def change
    create_table :train_staff_relations do |t|
      t.integer :train_id
      t.integer :staff_id
      t.boolean :status

      t.timestamps
    end
  end
end
