class AddIsChainToStores < ActiveRecord::Migration
  def change
    add_column :stores, :is_chain, :boolean
  end
end
