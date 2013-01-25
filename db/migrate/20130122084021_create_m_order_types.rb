class CreateMOrderTypes < ActiveRecord::Migration
  #物料支付类型表
  def change
    create_table :m_order_types do |t|
      t.integer :material_order_id  #所需物料订单编号
      t.integer :pay_types     
      t.float :price

    end
  end
end
