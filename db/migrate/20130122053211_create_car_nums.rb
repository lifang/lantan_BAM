class CreateCarNums < ActiveRecord::Migration
  def change
    create_table :car_nums do |t|
      t.string :num
      t.integer :car_model_id

    end
  end
end
