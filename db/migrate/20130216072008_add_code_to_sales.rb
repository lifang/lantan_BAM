class AddCodeToSales < ActiveRecord::Migration
  def change
    add_column :sales, :code, :string
  end
end
