class CreateSuppliers < ActiveRecord::Migration
  #供应商
  def change
    create_table :suppliers do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.string :address
      t.string :contact  #联系人
      t.integer :store_id
      t.integer :status
      t.timestamps
    end

    add_index :suppliers, :created_at
  end
end
