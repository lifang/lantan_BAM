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
      t.number :education
      t.number :nation
      t.number :political
      t.number :phone
      t.string :address
      t.string :photo
      t.number :base_salary
      t.integer :deduct_at   #提成开始数量
      t.interger :deduct_end  #提成结束数量
      t.float :deduct_percent
      t.boolean :status
      t.integer :store_id

      t.timestamps
    end
  end
end
