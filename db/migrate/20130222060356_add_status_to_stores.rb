class AddStatusToStores < ActiveRecord::Migration
  def change
    add_column :stores, :status, :integer

    add_index :stores, :status
  end
end
