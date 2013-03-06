class AddCodeToSales < ActiveRecord::Migration
  def change
    add_column :sales, :code, :string

    add_index :sales, :code
  end
end
