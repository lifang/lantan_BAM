class AddCodeToStores < ActiveRecord::Migration
  def change
    add_column :stores, :code, :string
  end
end
