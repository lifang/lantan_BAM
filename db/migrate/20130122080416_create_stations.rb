class CreateStations < ActiveRecord::Migration
  #工位表
  def change
    create_table :stations do |t|
      t.integer :status  #工位状态
      t.integer :store_id

      t.timestamps
    end
  end
end
