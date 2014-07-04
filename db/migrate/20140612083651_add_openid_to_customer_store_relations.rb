class AddOpenidToCustomerStoreRelations < ActiveRecord::Migration
  def change
    add_column :customers, :openid, :string
  end
end
