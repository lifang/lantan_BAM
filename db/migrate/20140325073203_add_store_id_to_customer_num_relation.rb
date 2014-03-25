class AddStoreIdToCustomerNumRelation < ActiveRecord::Migration
  def change
    add_column :customer_num_relations, :store_id, :integer
    add_column :c_pcard_relation, :store_id, :integer
    add_column :c_svc_relations, :store_id, :integer
  end
end
