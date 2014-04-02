class AddStoreIdToCustomerNumRelation < ActiveRecord::Migration
  def change
    add_column :customers, :store_id, :integer
    add_column :customers, :total_point, :integer,:default=>0
  end
end
