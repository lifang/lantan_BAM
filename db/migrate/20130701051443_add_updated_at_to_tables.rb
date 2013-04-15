class AddUpdatedAtToTables < ActiveRecord::Migration
  def change
    add_column :c_pcard_relations, :updated_at, :datetime
    add_column :c_svc_relations, :updated_at, :datetime
    add_column :capitals, :updated_at, :datetime
    add_column :car_brands, :updated_at, :datetime
    add_column :car_models, :updated_at, :datetime
    add_column :car_nums, :updated_at, :datetime
    add_column :chart_images, :updated_at, :datetime
    add_column :cities, :updated_at, :datetime
    add_column :customer_num_relations, :updated_at, :datetime
    add_column :goal_sale_types, :updated_at, :datetime
    add_column :goal_sales, :updated_at, :datetime
    add_column :image_urls, :updated_at, :datetime
    add_column :m_order_types, :updated_at, :datetime
    add_column :mat_in_orders, :updated_at, :datetime
    add_column :mat_order_items, :updated_at, :datetime
    add_column :mat_out_orders, :updated_at, :datetime
    add_column :menus, :updated_at, :datetime
    add_column :message_records, :updated_at, :datetime
    add_column :notices, :updated_at, :datetime
    add_column :order_pay_types, :updated_at, :datetime
    add_column :order_prod_relations, :updated_at, :datetime
    add_column :pcard_prod_relations, :updated_at, :datetime
    add_column :prod_mat_relations, :updated_at, :datetime
    add_column :res_prod_relations, :updated_at, :datetime
    add_column :reservations, :updated_at, :datetime
    add_column :revisit_order_relations, :updated_at, :datetime
    add_column :role_menu_relations, :updated_at, :datetime
    add_column :role_model_relations, :updated_at, :datetime
    add_column :roles, :updated_at, :datetime
    add_column :salaries, :updated_at, :datetime
    add_column :salary_details, :updated_at, :datetime
    add_column :sale_prod_relations, :updated_at, :datetime
    add_column :send_messages, :updated_at, :datetime
    add_column :staff_gr_records, :updated_at, :datetime
    add_column :staff_role_relations, :updated_at, :datetime
    add_column :station_staff_relations, :updated_at, :datetime
    add_column :store_complaints, :updated_at, :datetime
    add_column :store_pleasants, :updated_at, :datetime
    add_column :svc_return_records, :updated_at, :datetime
    add_column :svcard_prod_relations, :updated_at, :datetime
    add_column :svcard_use_records, :updated_at, :datetime
    add_column :train_staff_relations, :updated_at, :datetime
    add_column :syncs, :updated_at, :datetime
    add_column :trains, :updated_at, :datetime
    add_column :w_o_times, :updated_at, :datetime
    add_column :work_orders, :updated_at, :datetime
    add_column :work_records, :updated_at, :datetime
    add_column :models, :updated_at, :datetime


    add_index :c_pcard_relations, :updated_at
    add_index :c_svc_relations, :updated_at
    add_index :capitals, :updated_at
    add_index :car_brands, :updated_at
    add_index :car_models, :updated_at
    add_index :car_nums, :updated_at
    add_index :chart_images, :updated_at
    add_index :cities, :updated_at
    add_index :customer_num_relations, :updated_at
    add_index :goal_sale_types, :updated_at
    add_index :goal_sales, :updated_at
    add_index :image_urls, :updated_at
    add_index :m_order_types, :updated_at
    add_index :mat_in_orders, :updated_at
    add_index :mat_order_items, :updated_at
    add_index :mat_out_orders, :updated_at
    add_index :menus, :updated_at
    add_index :message_records, :updated_at
    add_index :notices, :updated_at
    add_index :order_pay_types, :updated_at
    add_index :order_prod_relations, :updated_at
    add_index :pcard_prod_relations, :updated_at
    add_index :prod_mat_relations, :updated_at
    add_index :res_prod_relations, :updated_at
    add_index :reservations, :updated_at
    add_index :revisit_order_relations, :updated_at
    add_index :role_menu_relations, :updated_at
    add_index :role_model_relations, :updated_at
    add_index :roles, :updated_at
    add_index :salaries, :updated_at
    add_index :salary_details, :updated_at
    add_index :sale_prod_relations, :updated_at
    add_index :send_messages, :updated_at
    add_index :staff_gr_records, :updated_at
    add_index :staff_role_relations, :updated_at
    add_index :station_staff_relations, :updated_at
    add_index :store_complaints, :updated_at
    add_index :store_pleasants, :updated_at
    add_index :svcard_prod_relations, :updated_at
    add_index :svcard_use_records, :updated_at
    add_index :train_staff_relations, :updated_at
    add_index :syncs, :updated_at
    add_index :trains, :updated_at
    add_index :w_o_times, :updated_at
    add_index :work_orders, :updated_at
    add_index :work_records, :updated_at
    add_index :models, :updated_at
  end

  
end
