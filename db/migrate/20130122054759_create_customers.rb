class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string :name
      t.string :mobilephone
      t.string :other_way  #其他联系方式
      t.boolean :sex
      t.datetime :birthday
      t.string :address
      t.boolean :is_vip
      t.string :mark  
      t.boolean :status
      t.integer :types

      t.timestamps
    end
  end
end
