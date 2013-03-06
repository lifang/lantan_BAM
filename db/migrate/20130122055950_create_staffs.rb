class CreateStaffs < ActiveRecord::Migration
  #员工表
  def change
    create_table :staffs do |t|
      t.string :name
      t.integer :type_of_w   #职务
      t.integer :position    #岗位
      t.boolean :sex
      t.integer :level       #等级
      t.datetime :birthday
      t.string :id_card      #身份证
      t.string :hometown
      t.integer :education
      t.string :nation
      t.integer :political
      t.string :phone
      t.string :address
      t.string :photo
      t.float :base_salary
      t.integer :deduct_at   #提成开始数量
      t.integer :deduct_end  #提成结束数量
      t.float :deduct_percent
      t.boolean :status, :default => 0
      t.integer :store_id

      t.timestamps
    end

    add_index :staffs, :name
    add_index :staffs, :status
    add_index :staffs, :store_id
    add_index :staffs, :level
    add_index :staffs, :type_of_w
    add_index :staffs, :position
  end
end
