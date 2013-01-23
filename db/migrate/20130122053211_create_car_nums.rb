class CreateCarNums < ActiveRecord::Migration
  def change
    create_table :car_nums do |t|
      t.integer :num
      t.integer :car_model_id

      t.timestamps
    end
  end
end
