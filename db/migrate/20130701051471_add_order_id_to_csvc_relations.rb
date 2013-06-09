class AddOrderIdToCsvcRelations < ActiveRecord::Migration
  def change
    add_column :c_svc_relations, :order_id, :integer
    add_column :c_svc_relations, :status, :boolean
  end
end
