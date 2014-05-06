class AddStoreIdToCustomerNumRelation < ActiveRecord::Migration
  def change
    change_column :customers, :total_point, :integer,:default=>0
  end
end
