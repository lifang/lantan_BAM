class ChangePriceToOrders < ActiveRecord::Migration
  change_column :sv_cards, :price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :m_order_types, :price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :material_orders, :price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :c_svc_relations, :total_price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :c_svc_relations, :left_price, :decimal,{:precision=>"20,2",:default=>0}
  

end
