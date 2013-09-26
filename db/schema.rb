# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.


ActiveRecord::Schema.define(:version => 20130924054439) do

  create_table "back_good_records", :force => true do |t|
    t.integer  "material_id"
    t.integer  "material_num"
    t.integer  "supplier_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "back_good_records", ["material_id"], :name => "index_back_good_records_on_material_id"

  create_table "c_pcard_relations", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "package_card_id"
    t.datetime "ended_at"
    t.integer  "status"
    t.text     "content"
    t.datetime "created_at"
    t.integer  "price"
    t.datetime "updated_at"
    t.integer  "order_id"
    t.integer  "return_types",    :default => 0
  end

  add_index "c_pcard_relations", ["order_id"], :name => "index_c_pcard_relations_on_order_id"
  add_index "c_pcard_relations", ["updated_at"], :name => "index_c_pcard_relations_on_updated_at"

  create_table "c_svc_relations", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "sv_card_id"
    t.float    "total_price"
    t.float    "left_price"
    t.string   "id_card"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "verify_code"
    t.integer  "order_id"
    t.boolean  "status"
    t.integer  "return_types", :default => 0
  end

  add_index "c_svc_relations", ["updated_at"], :name => "index_c_svc_relations_on_updated_at"

  create_table "capitals", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "capitals", ["created_at"], :name => "index_capitals_on_created_at"
  add_index "capitals", ["updated_at"], :name => "index_capitals_on_updated_at"

  create_table "car_brands", :force => true do |t|
    t.string   "name"
    t.integer  "capital_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "car_brands", ["created_at"], :name => "index_car_brands_on_created_at"
  add_index "car_brands", ["updated_at"], :name => "index_car_brands_on_updated_at"

  create_table "car_models", :force => true do |t|
    t.string   "name"
    t.integer  "car_brand_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "car_models", ["created_at"], :name => "index_car_models_on_created_at"
  add_index "car_models", ["updated_at"], :name => "index_car_models_on_updated_at"

  create_table "car_nums", :force => true do |t|
    t.string   "num"
    t.integer  "car_model_id"
    t.integer  "buy_year"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "car_nums", ["created_at"], :name => "index_car_nums_on_created_at"
  add_index "car_nums", ["updated_at"], :name => "index_car_nums_on_updated_at"

  create_table "chains", :force => true do |t|
    t.string   "name"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "staff_id"
  end

  create_table "chart_images", :force => true do |t|
    t.integer  "store_id"
    t.string   "image_url"
    t.integer  "types"
    t.datetime "created_at"
    t.datetime "current_day"
    t.integer  "staff_id"
    t.datetime "updated_at"
  end

  add_index "chart_images", ["created_at"], :name => "index_chart_images_on_created_at"
  add_index "chart_images", ["current_day"], :name => "index_chart_images_on_current_day"
  add_index "chart_images", ["store_id"], :name => "index_chart_images_on_store_id"
  add_index "chart_images", ["types"], :name => "index_chart_images_on_types"
  add_index "chart_images", ["updated_at"], :name => "index_chart_images_on_updated_at"

  create_table "cities", :force => true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cities", ["created_at"], :name => "index_cities_on_created_at"
  add_index "cities", ["updated_at"], :name => "index_cities_on_updated_at"

  create_table "complaints", :force => true do |t|
    t.integer  "order_id"
    t.text     "reason"
    t.text     "suggestion"
    t.text     "remark"
    t.boolean  "status"
    t.integer  "types"
    t.integer  "staff_id_1"
    t.integer  "staff_id_2"
    t.datetime "process_at"
    t.boolean  "is_violation"
    t.integer  "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "store_id"
    t.boolean  "c_feedback_suggestion"
  end

  create_table "customer_num_relations", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "car_num_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "customer_num_relations", ["created_at"], :name => "index_customer_num_relations_on_created_at"
  add_index "customer_num_relations", ["updated_at"], :name => "index_customer_num_relations_on_updated_at"

  create_table "customer_store_relations", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "total_point"
    t.boolean  "is_vip",      :default => false
  end

  add_index "customer_store_relations", ["customer_id"], :name => "index_customer_store_relations_on_customer_id"
  add_index "customer_store_relations", ["store_id"], :name => "index_customer_store_relations_on_store_id"

  create_table "customers", :force => true do |t|
    t.string   "name"
    t.string   "mobilephone"
    t.string   "other_way"
    t.boolean  "sex"
    t.datetime "birthday"
    t.string   "address"
    t.boolean  "is_vip"
    t.string   "mark"
    t.boolean  "status"
    t.integer  "types"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password"
    t.string   "username"
    t.string   "salt"
    t.integer  "total_point"
  end

  add_index "customers", ["username"], :name => "index_customers_on_username"

  create_table "depots", :force => true do |t|
    t.string   "name"
    t.integer  "status"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "depots", ["store_id"], :name => "index_depots_on_store_id"

  create_table "equipment_infos", :force => true do |t|
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "current_day"
    t.integer  "num"
    t.integer  "station_id"
  end

  add_index "equipment_infos", ["created_at"], :name => "index_equipment_infos_on_created_at"
  add_index "equipment_infos", ["station_id"], :name => "index_equipment_infos_on_station_id"
  add_index "equipment_infos", ["store_id"], :name => "index_equipment_infos_on_store_id"

  create_table "goal_sale_types", :force => true do |t|
    t.string   "type_name"
    t.integer  "goal_sale_id"
    t.float    "goal_price",    :default => 0.0
    t.float    "current_price", :default => 0.0
    t.integer  "types"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "goal_sale_types", ["created_at"], :name => "index_goal_sale_types_on_created_at"
  add_index "goal_sale_types", ["goal_sale_id"], :name => "index_goal_sale_types_on_goal_sale_id"
  add_index "goal_sale_types", ["type_name"], :name => "index_goal_sale_types_on_type_name"
  add_index "goal_sale_types", ["types"], :name => "index_goal_sale_types_on_types"
  add_index "goal_sale_types", ["updated_at"], :name => "index_goal_sale_types_on_updated_at"

  create_table "goal_sales", :force => true do |t|
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "goal_sales", ["updated_at"], :name => "index_goal_sales_on_updated_at"

  create_table "image_urls", :force => true do |t|
    t.integer  "product_id"
    t.string   "img_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "image_urls", ["created_at"], :name => "index_image_urls_on_created_at"
  add_index "image_urls", ["updated_at"], :name => "index_image_urls_on_updated_at"

  create_table "jv_syncs", :force => true do |t|
    t.integer  "types"
    t.datetime "current_day"
    t.integer  "hours"
    t.string   "zip_name"
    t.integer  "target_id"
  end

  add_index "jv_syncs", ["current_day"], :name => "index_jv_syncs_on_current_day"

  create_table "m_order_types", :force => true do |t|
    t.integer  "material_order_id"
    t.integer  "pay_types"
    t.float    "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "m_order_types", ["created_at"], :name => "index_m_order_types_on_created_at"
  add_index "m_order_types", ["updated_at"], :name => "index_m_order_types_on_updated_at"

  create_table "mat_depot_relations", :force => true do |t|
    t.integer  "depot_id"
    t.integer  "material_id"
    t.integer  "storage"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "check_num"
  end

  add_index "mat_depot_relations", ["depot_id"], :name => "index_mat_depot_relations_on_depot_id"
  add_index "mat_depot_relations", ["material_id"], :name => "index_mat_depot_relations_on_material_id"

  create_table "mat_in_orders", :force => true do |t|
    t.integer  "material_order_id"
    t.integer  "material_id"
    t.integer  "material_num"
    t.float    "price"
    t.integer  "staff_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mat_in_orders", ["updated_at"], :name => "index_mat_in_orders_on_updated_at"

  create_table "mat_order_items", :force => true do |t|
    t.integer  "material_order_id"
    t.integer  "material_id"
    t.integer  "material_num"
    t.float    "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mat_order_items", ["created_at"], :name => "index_mat_order_items_on_created_at"
  add_index "mat_order_items", ["updated_at"], :name => "index_mat_order_items_on_updated_at"

  create_table "mat_out_orders", :force => true do |t|
    t.integer  "material_id"
    t.integer  "staff_id"
    t.integer  "material_num"
    t.float    "price"
    t.integer  "material_order_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "types",             :limit => 1
    t.integer  "store_id"
  end

  add_index "mat_out_orders", ["updated_at"], :name => "index_mat_out_orders_on_updated_at"

  create_table "material_losses", :force => true do |t|
    t.integer  "loss_num"
    t.integer  "staff_id"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "material_id"
  end

  add_index "material_losses", ["material_id"], :name => "index_material_losses_on_material_id"
  add_index "material_losses", ["staff_id"], :name => "index_material_losses_on_staff_id"

  create_table "material_orders", :force => true do |t|
    t.string   "code"
    t.integer  "supplier_id"
    t.integer  "supplier_type"
    t.boolean  "status"
    t.integer  "staff_id"
    t.float    "price"
    t.datetime "arrival_at"
    t.string   "logistics_code"
    t.string   "carrier"
    t.integer  "store_id"
    t.string   "remark"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "m_status"
  end

  create_table "materials", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.float    "price"
    t.integer  "storage"
    t.integer  "types"
    t.boolean  "status"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remark",       :limit => 1000
    t.integer  "check_num"
    t.float    "sale_price"
    t.string   "unit"
    t.boolean  "is_ignore",                    :default => false
    t.integer  "material_low"
    t.string   "code_img"
  end

  create_table "menus", :force => true do |t|
    t.string   "controller"
    t.string   "name",       :limit => 45
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "menus", ["created_at"], :name => "index_menus_on_created_at"
  add_index "menus", ["updated_at"], :name => "index_menus_on_updated_at"

  create_table "message_records", :force => true do |t|
    t.string   "content"
    t.datetime "send_at"
    t.boolean  "status"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "message_records", ["updated_at"], :name => "index_message_records_on_updated_at"

  create_table "models", :force => true do |t|
    t.string   "name"
    t.integer  "num"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "models", ["updated_at"], :name => "index_models_on_updated_at"

  create_table "month_scores", :force => true do |t|
    t.integer  "sys_score"
    t.integer  "manage_score"
    t.integer  "current_month"
    t.boolean  "is_syss_update"
    t.integer  "staff_id"
    t.string   "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "news", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.boolean  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notices", :force => true do |t|
    t.integer  "target_id"
    t.integer  "types"
    t.text     "content"
    t.boolean  "status"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notices", ["updated_at"], :name => "index_notices_on_updated_at"

  create_table "o_pcard_relations", :force => true do |t|
    t.integer  "order_id"
    t.integer  "c_pcard_relation_id"
    t.integer  "product_id"
    t.integer  "product_num"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "order_pay_types", :force => true do |t|
    t.integer  "order_id"
    t.integer  "pay_type"
    t.float    "price"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "product_id"
    t.integer  "product_num"
  end

  add_index "order_pay_types", ["created_at"], :name => "index_order_pay_types_on_created_at"
  add_index "order_pay_types", ["updated_at"], :name => "index_order_pay_types_on_updated_at"

  create_table "order_prod_relations", :force => true do |t|
    t.integer  "order_id"
    t.integer  "product_id"
    t.integer  "pro_num"
    t.float    "price"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "total_price"
    t.float    "t_price"
    t.integer  "return_types", :default => 0
  end

  add_index "order_prod_relations", ["created_at"], :name => "index_order_prod_relations_on_created_at"
  add_index "order_prod_relations", ["updated_at"], :name => "index_order_prod_relations_on_updated_at"

  create_table "orders", :force => true do |t|
    t.string   "code"
    t.integer  "car_num_id"
    t.integer  "status"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.float    "price"
    t.boolean  "is_visited"
    t.integer  "is_pleased"
    t.boolean  "is_billing"
    t.integer  "front_staff_id"
    t.integer  "cons_staff_id_1"
    t.integer  "cons_staff_id_2"
    t.integer  "station_id"
    t.integer  "sale_id"
    t.integer  "c_pcard_relation_id"
    t.integer  "c_svc_relation_id"
    t.boolean  "is_free"
    t.integer  "types"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customer_id"
    t.string   "qfpos_id"
    t.datetime "auto_time"
  end

  create_table "package_cards", :force => true do |t|
    t.string   "name"
    t.string   "img_url"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer  "store_id"
    t.boolean  "status"
    t.integer  "price"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "date_types",     :default => 0
    t.integer  "date_month"
    t.boolean  "is_auto_revist"
    t.integer  "auto_time"
    t.text     "revist_content"
    t.integer  "prod_point"
    t.string   "description"
  end

  add_index "package_cards", ["updated_at"], :name => "index_package_cards_on_updated_at"

  create_table "pcard_material_relations", :force => true do |t|
    t.integer  "material_id"
    t.integer  "material_num"
    t.integer  "package_card_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pcard_material_relations", ["material_id"], :name => "index_pcard_material_relations_on_material_id"
  add_index "pcard_material_relations", ["package_card_id"], :name => "index_pcard_material_relations_on_package_card_id"

  create_table "pcard_prod_relations", :force => true do |t|
    t.integer  "product_id"
    t.integer  "product_num"
    t.integer  "package_card_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pcard_prod_relations", ["created_at"], :name => "index_pcard_prod_relations_on_created_at"
  add_index "pcard_prod_relations", ["updated_at"], :name => "index_pcard_prod_relations_on_updated_at"

  create_table "points", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "target_id"
    t.integer  "point_num"
    t.string   "target_content"
    t.integer  "types"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "points", ["customer_id"], :name => "index_points_on_customer_id"
  add_index "points", ["target_id"], :name => "index_points_on_target_id"

  create_table "prod_mat_relations", :force => true do |t|
    t.integer  "product_id"
    t.integer  "material_num"
    t.integer  "material_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "prod_mat_relations", ["created_at"], :name => "index_prod_mat_relations_on_created_at"
  add_index "prod_mat_relations", ["updated_at"], :name => "index_prod_mat_relations_on_updated_at"

  create_table "products", :force => true do |t|
    t.string   "name"
    t.float    "base_price"
    t.float    "sale_price"
    t.text     "description"
    t.integer  "types"
    t.string   "service_code"
    t.boolean  "status"
    t.text     "introduction"
    t.boolean  "is_service"
    t.integer  "staff_level"
    t.integer  "staff_level_1"
    t.string   "img_url"
    t.integer  "cost_time"
    t.integer  "store_id"
    t.string   "standard"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "deduct_percent"
    t.float    "t_price"
    t.boolean  "is_auto_revist"
    t.integer  "auto_time"
    t.text     "revist_content"
    t.integer  "prod_point"
    t.boolean  "show_on_ipad",   :default => false
    t.float    "deduct_price"
  end

  create_table "res_prod_relations", :force => true do |t|
    t.integer  "product_id"
    t.integer  "reservation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "res_prod_relations", ["created_at"], :name => "index_res_prod_relations_on_created_at"
  add_index "res_prod_relations", ["updated_at"], :name => "index_res_prod_relations_on_updated_at"

  create_table "reservations", :force => true do |t|
    t.integer  "car_num_id"
    t.datetime "res_time"
    t.boolean  "status"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "reservations", ["updated_at"], :name => "index_reservations_on_updated_at"

  create_table "revisit_order_relations", :force => true do |t|
    t.integer  "revisit_id"
    t.integer  "order_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "revisit_order_relations", ["created_at"], :name => "index_revisit_order_relations_on_created_at"
  add_index "revisit_order_relations", ["updated_at"], :name => "index_revisit_order_relations_on_updated_at"

  create_table "revisits", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "types"
    t.string   "title"
    t.string   "answer"
    t.integer  "complaint_id"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "role_menu_relations", :force => true do |t|
    t.integer  "role_id"
    t.integer  "menu_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "store_id"
  end

  add_index "role_menu_relations", ["created_at"], :name => "index_role_menu_relations_on_created_at"
  add_index "role_menu_relations", ["updated_at"], :name => "index_role_menu_relations_on_updated_at"

  create_table "role_model_relations", :force => true do |t|
    t.integer  "role_id"
    t.integer  "num"
    t.string   "model_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "store_id"
  end

  add_index "role_model_relations", ["created_at"], :name => "index_role_model_relations_on_created_at"
  add_index "role_model_relations", ["updated_at"], :name => "index_role_model_relations_on_updated_at"

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "store_id"
    t.integer  "role_type"
  end

  add_index "roles", ["created_at"], :name => "index_roles_on_created_at"
  add_index "roles", ["updated_at"], :name => "index_roles_on_updated_at"

  create_table "salaries", :force => true do |t|
    t.float    "deduct_num"
    t.float    "reward_num"
    t.float    "total"
    t.integer  "current_month"
    t.integer  "staff_id"
    t.integer  "satisfied_perc"
    t.datetime "created_at"
    t.boolean  "status",         :default => false
    t.datetime "updated_at"
  end

  add_index "salaries", ["updated_at"], :name => "index_salaries_on_updated_at"

  create_table "salary_details", :force => true do |t|
    t.integer  "current_day"
    t.float    "deduct_num"
    t.float    "reward_num"
    t.float    "satisfied_perc"
    t.integer  "staff_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "salary_details", ["updated_at"], :name => "index_salary_details_on_updated_at"

  create_table "sale_prod_relations", :force => true do |t|
    t.integer  "sale_id"
    t.integer  "product_id"
    t.integer  "prod_num"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sale_prod_relations", ["created_at"], :name => "index_sale_prod_relations_on_created_at"
  add_index "sale_prod_relations", ["updated_at"], :name => "index_sale_prod_relations_on_updated_at"

  create_table "sales", :force => true do |t|
    t.string   "name"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.text     "introduction"
    t.integer  "disc_types"
    t.integer  "status"
    t.float    "discount"
    t.integer  "store_id"
    t.integer  "disc_time_types"
    t.integer  "car_num"
    t.integer  "everycar_times"
    t.string   "img_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_subsidy"
    t.string   "sub_content"
    t.string   "code"
    t.string   "description"
  end

  create_table "send_messages", :force => true do |t|
    t.integer  "message_record_id"
    t.text     "content"
    t.integer  "customer_id"
    t.string   "phone"
    t.datetime "send_at"
    t.boolean  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "send_messages", ["created_at"], :name => "index_send_messages_on_created_at"
  add_index "send_messages", ["updated_at"], :name => "index_send_messages_on_updated_at"

  create_table "shared_materials", :force => true do |t|
    t.string   "code"
    t.string   "name"
    t.integer  "types",      :limit => 1
    t.string   "unit"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "staff_gr_records", :force => true do |t|
    t.integer  "staff_id"
    t.integer  "level"
    t.integer  "base_salary"
    t.integer  "deduct_at"
    t.integer  "deduct_end"
    t.float    "deduct_percent"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "working_stats"
  end

  add_index "staff_gr_records", ["updated_at"], :name => "index_staff_gr_records_on_updated_at"

  create_table "staff_role_relations", :force => true do |t|
    t.integer  "role_id"
    t.integer  "staff_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "staff_role_relations", ["created_at"], :name => "index_staff_role_relations_on_created_at"
  add_index "staff_role_relations", ["updated_at"], :name => "index_staff_role_relations_on_updated_at"

  create_table "staffs", :force => true do |t|
    t.string   "name"
    t.integer  "type_of_w"
    t.integer  "position"
    t.boolean  "sex"
    t.integer  "level"
    t.datetime "birthday"
    t.string   "id_card"
    t.string   "hometown"
    t.integer  "education"
    t.string   "nation"
    t.integer  "political"
    t.string   "phone"
    t.string   "address"
    t.string   "photo"
    t.float    "base_salary"
    t.integer  "deduct_at"
    t.integer  "deduct_end"
    t.float    "deduct_percent"
    t.integer  "status",             :limit => 1
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password"
    t.string   "username"
    t.string   "salt"
    t.boolean  "is_score_ge_salary",              :default => false
    t.integer  "working_stats"
    t.float    "probation_salary"
    t.boolean  "is_deduct"
    t.integer  "probation_days"
    t.string   "validate_code"
  end

  create_table "station_service_relations", :force => true do |t|
    t.integer  "station_id"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "station_staff_relations", :force => true do |t|
    t.integer  "station_id"
    t.integer  "staff_id"
    t.integer  "current_day"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "store_id"
  end

  add_index "station_staff_relations", ["store_id"], :name => "index_station_staff_relations_on_store_id"
  add_index "station_staff_relations", ["updated_at"], :name => "index_station_staff_relations_on_updated_at"

  create_table "stations", :force => true do |t|
    t.integer  "status"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "collector_code"
    t.string   "elec_switch"
    t.string   "clean_m_fb"
    t.string   "gas_t_switch"
    t.string   "gas_run_fb"
    t.string   "gas_error_fb"
    t.string   "system_error"
    t.string   "is_using"
    t.string   "day_hmi"
    t.string   "month_hmi"
    t.string   "once_gas_use"
    t.string   "once_water_use"
    t.integer  "staff_level"
    t.integer  "staff_level1"
    t.boolean  "is_has_controller"
    t.string   "code"
  end

  create_table "store_chains_relations", :force => true do |t|
    t.integer  "chain_id"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "store_chains_relations", ["chain_id"], :name => "index_store_chains_relations_on_chain_id"
  add_index "store_chains_relations", ["store_id"], :name => "index_store_chains_relations_on_store_id"

  create_table "store_complaints", :force => true do |t|
    t.string   "store_id"
    t.string   "img_url",    :limit => 1000
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "store_complaints", ["updated_at"], :name => "index_store_complaints_on_updated_at"

  create_table "store_pleasants", :force => true do |t|
    t.string   "store_id"
    t.string   "img_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "store_pleasants", ["created_at"], :name => "index_store_pleasants_on_created_at"
  add_index "store_pleasants", ["store_id"], :name => "index_store_pleasants_on_store_id"
  add_index "store_pleasants", ["updated_at"], :name => "index_store_pleasants_on_updated_at"

  create_table "stores", :force => true do |t|
    t.string   "name"
    t.string   "address"
    t.string   "phone"
    t.string   "contact"
    t.string   "email"
    t.string   "position"
    t.string   "introduction"
    t.string   "img_url"
    t.datetime "opened_at"
    t.float    "account"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "city_id"
    t.integer  "status"
    t.integer  "material_low"
    t.string   "code"
    t.integer  "edition_lv"
  end

  add_index "stores", ["code"], :name => "index_stores_on_code"
  add_index "stores", ["edition_lv"], :name => "index_stores_on_edition_lv"

  create_table "suppliers", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "phone"
    t.string   "address"
    t.string   "contact"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sv_cards", :force => true do |t|
    t.string   "name"
    t.string   "img_url"
    t.integer  "types"
    t.integer  "price"
    t.float    "discount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
    t.integer  "store_id"
    t.integer  "use_range"
    t.integer  "status",      :default => 1
  end

  create_table "svc_return_records", :force => true do |t|
    t.integer  "store_id"
    t.float    "price"
    t.integer  "types"
    t.text     "content"
    t.integer  "target_id"
    t.float    "total_price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "svcard_prod_relations", :force => true do |t|
    t.integer  "product_id"
    t.integer  "product_num"
    t.integer  "sv_card_id"
    t.float    "base_price"
    t.float    "more_price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "svcard_prod_relations", ["created_at"], :name => "index_svcard_prod_relations_on_created_at"
  add_index "svcard_prod_relations", ["updated_at"], :name => "index_svcard_prod_relations_on_updated_at"

  create_table "svcard_use_records", :force => true do |t|
    t.integer  "c_svc_relation_id"
    t.integer  "types"
    t.float    "use_price"
    t.float    "left_price"
    t.datetime "created_at"
    t.string   "content"
    t.datetime "updated_at"
  end

  add_index "svcard_use_records", ["updated_at"], :name => "index_svcard_use_records_on_updated_at"

  create_table "syncs", :force => true do |t|
    t.integer  "store_id"
    t.datetime "sync_at"
    t.datetime "created_at"
    t.boolean  "data_status", :default => false
    t.boolean  "sync_status", :default => false
    t.string   "zip_name"
    t.integer  "types"
    t.boolean  "has_data",    :default => true
    t.datetime "updated_at"
  end

  add_index "syncs", ["created_at"], :name => "index_syncs_on_created_at"
  add_index "syncs", ["sync_at"], :name => "index_syncs_on_sync_at"
  add_index "syncs", ["updated_at"], :name => "index_syncs_on_updated_at"

  create_table "total_msgs", :force => true do |t|
    t.string   "shop"
    t.integer  "msgnum"
    t.string   "msg1"
    t.string   "msg2"
    t.string   "msg3"
    t.string   "msg4"
    t.string   "msg5"
    t.string   "msg6"
    t.string   "msg7"
    t.string   "msg8"
    t.string   "msg9"
    t.string   "msg10"
    t.string   "msg11"
    t.string   "msg12"
    t.string   "msg13"
    t.string   "msg14"
    t.string   "msg15"
    t.string   "msg16"
    t.string   "msg17"
    t.string   "msg18"
    t.string   "msg19"
    t.string   "msg20"
    t.string   "msg21"
    t.string   "msg22"
    t.string   "msg23"
    t.string   "msg24"
    t.string   "msg25"
    t.string   "msg26"
    t.string   "msg27"
    t.string   "msg28"
    t.string   "msg29"
    t.string   "msg30"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "train_staff_relations", :force => true do |t|
    t.integer  "train_id"
    t.integer  "staff_id"
    t.boolean  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "train_staff_relations", ["created_at"], :name => "index_train_staff_relations_on_created_at"
  add_index "train_staff_relations", ["updated_at"], :name => "index_train_staff_relations_on_updated_at"

  create_table "trains", :force => true do |t|
    t.string   "content"
    t.datetime "start_at"
    t.datetime "end_at"
    t.boolean  "certificate"
    t.datetime "created_at"
    t.integer  "train_type"
    t.datetime "updated_at"
  end

  add_index "trains", ["updated_at"], :name => "index_trains_on_updated_at"

  create_table "violation_rewards", :force => true do |t|
    t.integer  "staff_id"
    t.string   "situation"
    t.boolean  "status"
    t.integer  "process_types"
    t.string   "mark"
    t.boolean  "types"
    t.integer  "target_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "score_num"
    t.float    "salary_num"
    t.datetime "process_at"
  end

  create_table "wk_or_times", :force => true do |t|
    t.integer  "current_time"
    t.integer  "current_day"
    t.integer  "station_id"
    t.integer  "worked_num"
    t.integer  "wait_num"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "wk_or_times", ["updated_at"], :name => "index_wk_or_times_on_updated_at"

  create_table "work_orders", :force => true do |t|
    t.integer  "station_id"
    t.integer  "status"
    t.integer  "order_id"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer  "current_day"
    t.float    "runtime"
    t.float    "violation_num"
    t.string   "violation_reason"
    t.float    "water_num"
    t.float    "electricity_num"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "gas_num"
    t.integer  "cost_time"
  end

  add_index "work_orders", ["updated_at"], :name => "index_work_orders_on_updated_at"

  create_table "work_records", :force => true do |t|
    t.datetime "current_day"
    t.integer  "attendance_num"
    t.integer  "construct_num"
    t.integer  "materials_used_num"
    t.integer  "materials_consume_num"
    t.float    "water_num"
    t.float    "elec_num"
    t.integer  "complaint_num"
    t.integer  "train_num"
    t.float    "violation_num"
    t.integer  "reward_num"
    t.integer  "staff_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "gas_num"
    t.integer  "store_id"
  end

  add_index "work_records", ["updated_at"], :name => "index_work_records_on_updated_at"

end
