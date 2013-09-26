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
    t.integer  "price",           :default => 0
    t.datetime "updated_at"
    t.integer  "order_id"
  end

  add_index "c_pcard_relations", ["customer_id"], :name => "index_c_pcard_relations_on_customer_id"
  add_index "c_pcard_relations", ["order_id"], :name => "index_c_pcard_relations_on_order_id"
  add_index "c_pcard_relations", ["package_card_id"], :name => "index_c_pcard_relations_on_package_card_id"
  add_index "c_pcard_relations", ["status"], :name => "index_c_pcard_relations_on_status"

  create_table "c_svc_relations", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "sv_card_id"
    t.float    "total_price"
    t.float    "left_price"
    t.string   "id_card"
    t.boolean  "is_billing"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "verify_code"
    t.integer  "order_id"
    t.boolean  "status"
  end

  add_index "c_svc_relations", ["customer_id"], :name => "index_c_svc_relations_on_customer_id"
  add_index "c_svc_relations", ["sv_card_id"], :name => "index_c_svc_relations_on_sv_card_id"

  create_table "capitals", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "capitals", ["created_at"], :name => "index_capitals_on_created_at"

  create_table "car_brands", :force => true do |t|
    t.string   "name"
    t.integer  "capital_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "car_brands", ["capital_id"], :name => "index_car_brands_on_capital_id"
  add_index "car_brands", ["created_at"], :name => "index_car_brands_on_created_at"
  add_index "car_brands", ["name"], :name => "index_car_brands_on_name"

  create_table "car_models", :force => true do |t|
    t.string   "name"
    t.integer  "car_brand_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "car_models", ["car_brand_id"], :name => "index_car_models_on_car_brand_id"
  add_index "car_models", ["created_at"], :name => "index_car_models_on_created_at"
  add_index "car_models", ["name"], :name => "index_car_models_on_name"

  create_table "car_nums", :force => true do |t|
    t.string   "num"
    t.integer  "car_model_id"
    t.integer  "buy_year"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "car_nums", ["car_model_id"], :name => "index_car_nums_on_car_model_id"
  add_index "car_nums", ["created_at"], :name => "index_car_nums_on_created_at"
  add_index "car_nums", ["num"], :name => "index_car_nums_on_num"

  create_table "chains", :force => true do |t|
    t.string   "name"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "staff_id"
  end

  create_table "char_images", :force => true do |t|
    t.integer  "city_id"
    t.datetime "current_month"
    t.string   "image_url"
    t.datetime "created_at"
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

  create_table "cities", :force => true do |t|
    t.integer  "order_index"
    t.string   "name"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cities", ["created_at"], :name => "index_cities_on_created_at"
  add_index "cities", ["order_index"], :name => "index_cities_on_order_index"
  add_index "cities", ["parent_id"], :name => "index_cities_on_parent_id"

  create_table "complaints", :force => true do |t|
    t.integer  "order_id"
    t.text     "reason"
    t.text     "suggestion"
    t.text     "remark"
    t.boolean  "status",                :default => false
    t.integer  "types"
    t.integer  "staff_id_1"
    t.integer  "staff_id_2"
    t.datetime "process_at"
    t.boolean  "is_violation"
    t.integer  "customer_id"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "c_feedback_suggestion"
  end

  add_index "complaints", ["customer_id"], :name => "index_complaints_on_customer_id"
  add_index "complaints", ["order_id"], :name => "index_complaints_on_order_id"
  add_index "complaints", ["staff_id_1"], :name => "index_complaints_on_staff_id_1"
  add_index "complaints", ["staff_id_2"], :name => "index_complaints_on_staff_id_2"
  add_index "complaints", ["store_id"], :name => "index_complaints_on_store_id"
  add_index "complaints", ["types"], :name => "index_complaints_on_types"

  create_table "customer_num_relations", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "car_num_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "customer_num_relations", ["car_num_id"], :name => "index_customer_num_relations_on_car_num_id"
  add_index "customer_num_relations", ["created_at"], :name => "index_customer_num_relations_on_created_at"
  add_index "customer_num_relations", ["customer_id"], :name => "index_customer_num_relations_on_customer_id"

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
    t.boolean  "is_vip",             :default => false
    t.string   "mark"
    t.boolean  "status",             :default => false
    t.integer  "types"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password"
    t.string   "username"
    t.string   "salt"
    t.integer  "total_point"
  end

  add_index "customers", ["birthday"], :name => "index_customers_on_birthday"
  add_index "customers", ["is_vip"], :name => "index_customers_on_is_vip"
  add_index "customers", ["mobilephone"], :name => "index_customers_on_mobilephone"
  add_index "customers", ["name"], :name => "index_customers_on_name"
  add_index "customers", ["status"], :name => "index_customers_on_status"
  add_index "customers", ["types"], :name => "index_customers_on_types"
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

  create_table "goal_sales", :force => true do |t|
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer  "store_id"
    t.datetime "created_at"
  end

  add_index "goal_sales", ["created_at"], :name => "index_goal_sales_on_created_at"
  add_index "goal_sales", ["store_id"], :name => "index_goal_sales_on_store_id"

  create_table "image_urls", :force => true do |t|
    t.integer  "product_id"
    t.string   "img_url"
    t.datetime "created_at"
  end

  add_index "image_urls", ["created_at"], :name => "index_image_urls_on_created_at"
  add_index "image_urls", ["product_id"], :name => "index_image_urls_on_product_id"

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
  end

  add_index "m_order_types", ["created_at"], :name => "index_m_order_types_on_created_at"
  add_index "m_order_types", ["material_order_id"], :name => "index_m_order_types_on_material_order_id"
  add_index "m_order_types", ["pay_types"], :name => "index_m_order_types_on_pay_types"

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
  end

  add_index "mat_in_orders", ["created_at"], :name => "index_mat_in_orders_on_created_at"
  add_index "mat_in_orders", ["material_id"], :name => "index_mat_in_orders_on_material_id"
  add_index "mat_in_orders", ["material_order_id"], :name => "index_mat_in_orders_on_material_order_id"
  add_index "mat_in_orders", ["staff_id"], :name => "index_mat_in_orders_on_staff_id"

  create_table "mat_order_items", :force => true do |t|
    t.integer  "material_order_id"
    t.integer  "material_id"
    t.integer  "material_num"
    t.float    "price"
    t.datetime "created_at"
  end

  add_index "mat_order_items", ["created_at"], :name => "index_mat_order_items_on_created_at"
  add_index "mat_order_items", ["material_id"], :name => "index_mat_order_items_on_material_id"
  add_index "mat_order_items", ["material_order_id"], :name => "index_mat_order_items_on_material_order_id"

  create_table "mat_out_orders", :force => true do |t|
    t.integer  "material_id"
    t.integer  "staff_id"
    t.integer  "material_num"
    t.float    "price"
    t.integer  "material_order_id"
    t.datetime "created_at"
    t.integer  "types",             :limit => 1
    t.integer  "store_id"
  end

  add_index "mat_out_orders", ["created_at"], :name => "index_mat_out_orders_on_created_at"
  add_index "mat_out_orders", ["material_id"], :name => "index_mat_out_orders_on_material_id"
  add_index "mat_out_orders", ["material_order_id"], :name => "index_mat_out_orders_on_material_order_id"
  add_index "mat_out_orders", ["staff_id"], :name => "index_mat_out_orders_on_staff_id"

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
    t.integer  "status"
    t.integer  "staff_id"
    t.float    "price"
    t.datetime "arrival_at"
    t.string   "logistics_code"
    t.string   "carrier"
    t.integer  "store_id"
    t.string   "remark"
    t.integer  "sale_id"
    t.integer  "m_status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "material_orders", ["code"], :name => "index_material_orders_on_code"
  add_index "material_orders", ["m_status"], :name => "index_material_orders_on_m_status"
  add_index "material_orders", ["sale_id"], :name => "index_material_orders_on_sale_id"
  add_index "material_orders", ["staff_id"], :name => "index_material_orders_on_staff_id"
  add_index "material_orders", ["status"], :name => "index_material_orders_on_status"
  add_index "material_orders", ["store_id"], :name => "index_material_orders_on_store_id"
  add_index "material_orders", ["supplier_id"], :name => "index_material_orders_on_supplier_id"
  add_index "material_orders", ["supplier_type"], :name => "index_material_orders_on_supplier_type"

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
    t.boolean  "is_ignore",                    :default => false
    t.float    "sale_price"
    t.string   "unit"
    t.integer  "material_low"
  end

  add_index "materials", ["name"], :name => "index_materials_on_name"
  add_index "materials", ["status"], :name => "index_materials_on_status"
  add_index "materials", ["store_id"], :name => "index_materials_on_store_id"
  add_index "materials", ["types"], :name => "index_materials_on_types"

  create_table "menus", :force => true do |t|
    t.string   "controller"
    t.string   "name"
    t.datetime "created_at"
  end

  add_index "menus", ["controller"], :name => "index_menus_on_controller"
  add_index "menus", ["created_at"], :name => "index_menus_on_created_at"

  create_table "message_records", :force => true do |t|
    t.text     "content"
    t.datetime "send_at"
    t.boolean  "status",     :default => false
    t.integer  "store_id"
    t.datetime "created_at"
  end

  add_index "message_records", ["status"], :name => "index_message_records_on_status"
  add_index "message_records", ["store_id"], :name => "index_message_records_on_store_id"

  create_table "month_scores", :force => true do |t|
    t.integer  "sys_score"
    t.integer  "manage_score"
    t.integer  "current_month"
    t.boolean  "is_syss_update"
    t.integer  "staff_id"
    t.string   "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "store_id"
  end

  add_index "month_scores", ["current_month"], :name => "index_month_scores_on_current_month"
  add_index "month_scores", ["manage_score"], :name => "index_month_scores_on_manage_score"
  add_index "month_scores", ["staff_id"], :name => "index_month_scores_on_staff_id"
  add_index "month_scores", ["sys_score"], :name => "index_month_scores_on_sys_score"

  create_table "news", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.integer  "status",     :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "news", ["created_at"], :name => "index_news_on_created_at"
  add_index "news", ["status"], :name => "index_news_on_status"

  create_table "notices", :force => true do |t|
    t.integer  "target_id"
    t.integer  "types"
    t.text     "content"
    t.boolean  "status"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notices", ["status"], :name => "index_notices_on_status"
  add_index "notices", ["store_id"], :name => "index_notices_on_store_id"
  add_index "notices", ["types"], :name => "index_notices_on_types"
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
    t.integer  "product_id"
    t.integer  "product_num"
  end

  add_index "order_pay_types", ["created_at"], :name => "index_order_pay_types_on_created_at"
  add_index "order_pay_types", ["order_id"], :name => "index_order_pay_types_on_order_id"
  add_index "order_pay_types", ["pay_type"], :name => "index_order_pay_types_on_pay_type"

  create_table "order_prod_relations", :force => true do |t|
    t.integer  "order_id"
    t.integer  "product_id"
    t.integer  "pro_num"
    t.float    "price"
    t.datetime "created_at"
    t.float    "total_price"
    t.float    "t_price"
  end

  add_index "order_prod_relations", ["created_at"], :name => "index_order_prod_relations_on_created_at"
  add_index "order_prod_relations", ["order_id"], :name => "index_order_prod_relations_on_order_id"
  add_index "order_prod_relations", ["product_id"], :name => "index_order_prod_relations_on_product_id"

  create_table "orders", :force => true do |t|
    t.string   "code"
    t.integer  "car_num_id"
    t.integer  "status",              :limit => 2
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

  add_index "orders", ["c_pcard_relation_id"], :name => "index_orders_on_c_pcard_relation_id"
  add_index "orders", ["c_svc_relation_id"], :name => "index_orders_on_c_svc_relation_id"
  add_index "orders", ["car_num_id"], :name => "index_orders_on_car_num_id"
  add_index "orders", ["code"], :name => "index_orders_on_code"
  add_index "orders", ["cons_staff_id_1"], :name => "index_orders_on_cons_staff_id_1"
  add_index "orders", ["cons_staff_id_2"], :name => "index_orders_on_cons_staff_id_2"
  add_index "orders", ["created_at"], :name => "index_orders_on_created_at"
  add_index "orders", ["customer_id"], :name => "index_orders_on_customer_id"
  add_index "orders", ["front_staff_id"], :name => "index_orders_on_front_staff_id"
  add_index "orders", ["is_visited"], :name => "index_orders_on_is_visited"
  add_index "orders", ["price"], :name => "index_orders_on_price"
  add_index "orders", ["sale_id"], :name => "index_orders_on_sale_id"
  add_index "orders", ["station_id"], :name => "index_orders_on_station_id"
  add_index "orders", ["status"], :name => "index_orders_on_status"
  add_index "orders", ["store_id"], :name => "index_orders_on_store_id"
  add_index "orders", ["types"], :name => "index_orders_on_types"

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

  add_index "package_cards", ["created_at"], :name => "index_package_cards_on_created_at"
  add_index "package_cards", ["status"], :name => "index_package_cards_on_status"
  add_index "package_cards", ["store_id"], :name => "index_package_cards_on_store_id"
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
  end

  add_index "pcard_prod_relations", ["created_at"], :name => "index_pcard_prod_relations_on_created_at"
  add_index "pcard_prod_relations", ["package_card_id"], :name => "index_pcard_prod_relations_on_package_card_id"
  add_index "pcard_prod_relations", ["product_id"], :name => "index_pcard_prod_relations_on_product_id"

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
  end

  add_index "prod_mat_relations", ["created_at"], :name => "index_prod_mat_relations_on_created_at"
  add_index "prod_mat_relations", ["material_id"], :name => "index_prod_mat_relations_on_material_id"
  add_index "prod_mat_relations", ["product_id"], :name => "index_prod_mat_relations_on_product_id"

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
    t.float    "deduct_price"
    t.boolean  "show_on_ipad",   :default => true
  end

  add_index "products", ["is_service"], :name => "index_products_on_is_service"
  add_index "products", ["name"], :name => "index_products_on_name"
  add_index "products", ["status"], :name => "index_products_on_status"
  add_index "products", ["store_id"], :name => "index_products_on_store_id"
  add_index "products", ["types"], :name => "index_products_on_types"

  create_table "res_prod_relations", :force => true do |t|
    t.integer  "product_id"
    t.integer  "reservation_id"
    t.datetime "created_at"
  end

  add_index "res_prod_relations", ["created_at"], :name => "index_res_prod_relations_on_created_at"
  add_index "res_prod_relations", ["product_id"], :name => "index_res_prod_relations_on_product_id"
  add_index "res_prod_relations", ["reservation_id"], :name => "index_res_prod_relations_on_reservation_id"

  create_table "reservations", :force => true do |t|
    t.integer  "car_num_id"
    t.datetime "res_time"
    t.integer  "status"
    t.integer  "store_id"
    t.datetime "created_at"
    t.integer  "customer_id"
  end

  add_index "reservations", ["car_num_id"], :name => "index_reservations_on_car_num_id"
  add_index "reservations", ["created_at"], :name => "index_reservations_on_created_at"
  add_index "reservations", ["status"], :name => "index_reservations_on_status"
  add_index "reservations", ["store_id"], :name => "index_reservations_on_store_id"

  create_table "revisit_order_relations", :force => true do |t|
    t.integer  "revisit_id"
    t.integer  "order_id"
    t.datetime "created_at"
  end

  add_index "revisit_order_relations", ["created_at"], :name => "index_revisit_order_relations_on_created_at"
  add_index "revisit_order_relations", ["order_id"], :name => "index_revisit_order_relations_on_order_id"
  add_index "revisit_order_relations", ["revisit_id"], :name => "index_revisit_order_relations_on_revisit_id"

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

  add_index "revisits", ["complaint_id"], :name => "index_revisits_on_complaint_id"
  add_index "revisits", ["customer_id"], :name => "index_revisits_on_customer_id"
  add_index "revisits", ["title"], :name => "index_revisits_on_title"
  add_index "revisits", ["types"], :name => "index_revisits_on_types"

  create_table "role_menu_relations", :force => true do |t|
    t.integer  "role_id"
    t.integer  "menu_id"
    t.datetime "created_at"
    t.integer  "store_id"
  end

  add_index "role_menu_relations", ["created_at"], :name => "index_role_menu_relations_on_created_at"
  add_index "role_menu_relations", ["menu_id"], :name => "index_role_menu_relations_on_menu_id"
  add_index "role_menu_relations", ["role_id"], :name => "index_role_menu_relations_on_role_id"

  create_table "role_model_relations", :force => true do |t|
    t.integer  "role_id"
    t.integer  "num"
    t.string   "model_name"
    t.datetime "created_at"
    t.integer  "store_id"
  end

  add_index "role_model_relations", ["created_at"], :name => "index_role_model_relations_on_created_at"
  add_index "role_model_relations", ["role_id"], :name => "index_role_model_relations_on_role_id"

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.integer  "store_id"
    t.integer  "role_type"
  end

  add_index "roles", ["created_at"], :name => "index_roles_on_created_at"

  create_table "salaries", :force => true do |t|
    t.float    "deduct_num"
    t.float    "reward_num"
    t.float    "total"
    t.integer  "current_month"
    t.integer  "staff_id"
    t.integer  "satisfied_perc"
    t.datetime "created_at"
    t.boolean  "status",         :default => false
  end

  add_index "salaries", ["current_month"], :name => "index_salaries_on_current_month"
  add_index "salaries", ["staff_id"], :name => "index_salaries_on_staff_id"
  add_index "salaries", ["status"], :name => "index_salaries_on_status"

  create_table "salary_details", :force => true do |t|
    t.integer  "current_day"
    t.float    "deduct_num"
    t.float    "reward_num"
    t.float    "satisfied_perc"
    t.integer  "staff_id"
    t.datetime "created_at"
  end

  add_index "salary_details", ["current_day"], :name => "index_salary_details_on_current_day"
  add_index "salary_details", ["staff_id"], :name => "index_salary_details_on_staff_id"

  create_table "sale_prod_relations", :force => true do |t|
    t.integer  "sale_id"
    t.integer  "product_id"
    t.integer  "prod_num"
    t.datetime "created_at"
  end

  add_index "sale_prod_relations", ["created_at"], :name => "index_sale_prod_relations_on_created_at"
  add_index "sale_prod_relations", ["product_id"], :name => "index_sale_prod_relations_on_product_id"
  add_index "sale_prod_relations", ["sale_id"], :name => "index_sale_prod_relations_on_sale_id"

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

  add_index "sales", ["code"], :name => "index_sales_on_code"
  add_index "sales", ["created_at"], :name => "index_sales_on_created_at"
  add_index "sales", ["status"], :name => "index_sales_on_status"
  add_index "sales", ["store_id"], :name => "index_sales_on_store_id"

  create_table "send_messages", :force => true do |t|
    t.integer  "message_record_id"
    t.text     "content"
    t.integer  "customer_id"
    t.string   "phone"
    t.datetime "send_at"
    t.boolean  "status"
    t.datetime "created_at"
  end

  add_index "send_messages", ["created_at"], :name => "index_send_messages_on_created_at"
  add_index "send_messages", ["message_record_id"], :name => "index_send_messages_on_message_record_id"
  add_index "send_messages", ["status"], :name => "index_send_messages_on_status"

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
    t.integer  "working_stats"
  end

  add_index "staff_gr_records", ["created_at"], :name => "index_staff_gr_records_on_created_at"
  add_index "staff_gr_records", ["staff_id"], :name => "index_staff_gr_records_on_staff_id"

  create_table "staff_role_relations", :force => true do |t|
    t.integer  "role_id"
    t.integer  "staff_id"
    t.datetime "created_at"
  end

  add_index "staff_role_relations", ["created_at"], :name => "index_staff_role_relations_on_created_at"
  add_index "staff_role_relations", ["role_id"], :name => "index_staff_role_relations_on_role_id"
  add_index "staff_role_relations", ["staff_id"], :name => "index_staff_role_relations_on_staff_id"

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
    t.string   "political"
    t.string   "phone"
    t.string   "address"
    t.string   "photo"
    t.float    "base_salary"
    t.integer  "deduct_at"
    t.integer  "deduct_end"
    t.float    "deduct_percent"
    t.integer  "status",             :limit => 1, :default => 0
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

  add_index "staffs", ["level"], :name => "index_staffs_on_level"
  add_index "staffs", ["name"], :name => "index_staffs_on_name"
  add_index "staffs", ["position"], :name => "index_staffs_on_position"
  add_index "staffs", ["status"], :name => "index_staffs_on_status"
  add_index "staffs", ["store_id"], :name => "index_staffs_on_store_id"
  add_index "staffs", ["type_of_w"], :name => "index_staffs_on_type_of_w"
  add_index "staffs", ["username"], :name => "index_staffs_on_username"

  create_table "station_service_relations", :force => true do |t|
    t.integer  "station_id"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "station_service_relations", ["product_id"], :name => "index_station_service_relations_on_product_id"
  add_index "station_service_relations", ["station_id"], :name => "index_station_service_relations_on_station_id"

  create_table "station_staff_relations", :force => true do |t|
    t.integer  "station_id"
    t.integer  "staff_id"
    t.integer  "current_day"
    t.datetime "created_at"
    t.integer  "store_id"
  end

  add_index "station_staff_relations", ["current_day"], :name => "index_station_staff_relations_on_current_day"
  add_index "station_staff_relations", ["staff_id"], :name => "index_station_staff_relations_on_staff_id"
  add_index "station_staff_relations", ["station_id"], :name => "index_station_staff_relations_on_station_id"
  add_index "station_staff_relations", ["store_id"], :name => "index_station_staff_relations_on_store_id"

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
    t.boolean  "is_has_controller"
    t.integer  "staff_level"
    t.integer  "staff_level1"
    t.string   "code"
  end

  add_index "stations", ["status"], :name => "index_stations_on_status"
  add_index "stations", ["store_id"], :name => "index_stations_on_store_id"

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
    t.string   "img_url"
    t.datetime "created_at"
  end

  add_index "store_complaints", ["created_at"], :name => "index_store_complaints_on_created_at"
  add_index "store_complaints", ["store_id"], :name => "index_store_complaints_on_store_id"

  create_table "store_pleasants", :force => true do |t|
    t.string   "store_id"
    t.string   "img_url"
    t.datetime "created_at"
  end

  add_index "store_pleasants", ["created_at"], :name => "index_store_pleasants_on_created_at"
  add_index "store_pleasants", ["store_id"], :name => "index_store_pleasants_on_store_id"

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

  add_index "stores", ["city_id"], :name => "index_stores_on_city_id"
  add_index "stores", ["code"], :name => "index_stores_on_code"
  add_index "stores", ["created_at"], :name => "index_stores_on_created_at"
  add_index "stores", ["edition_lv"], :name => "index_stores_on_edition_lv"
  add_index "stores", ["status"], :name => "index_stores_on_status"

  create_table "suppliers", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "phone"
    t.string   "address"
    t.string   "contact"
    t.integer  "store_id"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "suppliers", ["created_at"], :name => "index_suppliers_on_created_at"

  create_table "sv_cards", :force => true do |t|
    t.string   "name"
    t.string   "img_url"
    t.integer  "types"
    t.float    "price",       :limit => 11
    t.float    "discount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
    t.integer  "store_id"
    t.integer  "use_range"
    t.integer  "status"
  end

  add_index "sv_cards", ["types"], :name => "index_sv_cards_on_types"

  create_table "svc_return_records", :force => true do |t|
    t.integer  "store_id"
    t.float    "price"
    t.integer  "types"
    t.text     "content"
    t.integer  "target_id"
    t.float    "total_price"
    t.datetime "created_at"
  end

  add_index "svc_return_records", ["created_at"], :name => "index_svc_return_records_on_created_at"
  add_index "svc_return_records", ["store_id"], :name => "index_svc_return_records_on_store_id"

  create_table "svcard_prod_relations", :force => true do |t|
    t.integer  "product_id"
    t.integer  "product_num"
    t.integer  "sv_card_id"
    t.float    "base_price"
    t.float    "more_price"
    t.datetime "created_at"
  end

  add_index "svcard_prod_relations", ["created_at"], :name => "index_svcard_prod_relations_on_created_at"
  add_index "svcard_prod_relations", ["product_id"], :name => "index_svcard_prod_relations_on_product_id"
  add_index "svcard_prod_relations", ["sv_card_id"], :name => "index_svcard_prod_relations_on_sv_card_id"

  create_table "svcard_use_records", :force => true do |t|
    t.integer  "c_svc_relation_id"
    t.integer  "types"
    t.float    "use_price"
    t.float    "left_price"
    t.datetime "created_at"
    t.string   "content"
  end

  add_index "svcard_use_records", ["c_svc_relation_id"], :name => "index_svcard_use_records_on_c_svc_relation_id"
  add_index "svcard_use_records", ["types"], :name => "index_svcard_use_records_on_types"

  create_table "syncs", :force => true do |t|
    t.integer  "store_id"
    t.datetime "sync_at"
    t.datetime "created_at"
    t.boolean  "data_status", :default => false
    t.string   "zip_name",    :default => "0"
    t.boolean  "sync_status", :default => false
    t.integer  "types"
    t.boolean  "has_data",    :default => true
  end

  add_index "syncs", ["created_at"], :name => "index_syncs_on_created_at"
  add_index "syncs", ["sync_at"], :name => "index_syncs_on_sync_at"

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
  end

  add_index "train_staff_relations", ["created_at"], :name => "index_train_staff_relations_on_created_at"
  add_index "train_staff_relations", ["staff_id"], :name => "index_train_staff_relations_on_staff_id"
  add_index "train_staff_relations", ["status"], :name => "index_train_staff_relations_on_status"
  add_index "train_staff_relations", ["train_id"], :name => "index_train_staff_relations_on_train_id"

  create_table "trains", :force => true do |t|
    t.string   "content"
    t.datetime "start_at"
    t.datetime "end_at"
    t.boolean  "certificate"
    t.datetime "created_at"
    t.integer  "train_type"
  end

  create_table "violation_rewards", :force => true do |t|
    t.integer  "staff_id"
    t.string   "situation"
    t.boolean  "status",        :default => false
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

  add_index "violation_rewards", ["created_at"], :name => "index_violation_rewards_on_created_at"
  add_index "violation_rewards", ["staff_id"], :name => "index_violation_rewards_on_staff_id"

  create_table "w_o_times", :force => true do |t|
    t.integer  "current_time"
    t.integer  "current_day"
    t.integer  "station_id"
    t.integer  "worked_num"
    t.integer  "wait_num"
    t.datetime "created_at"
  end

  create_table "wk_or_times", :force => true do |t|
    t.string   "current_time", :limit => 20
    t.integer  "current_day"
    t.integer  "station_id"
    t.integer  "worked_num"
    t.integer  "wait_num"
    t.datetime "created_at"
  end

  add_index "wk_or_times", ["current_day"], :name => "index_w_o_times_on_current_day"
  add_index "wk_or_times", ["station_id"], :name => "index_w_o_times_on_station_id"

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
    t.float    "gas_num"
    t.integer  "cost_time"
  end

  add_index "work_orders", ["current_day"], :name => "index_work_orders_on_current_day"
  add_index "work_orders", ["order_id"], :name => "index_work_orders_on_order_id"
  add_index "work_orders", ["station_id"], :name => "index_work_orders_on_station_id"
  add_index "work_orders", ["status"], :name => "index_work_orders_on_status"
  add_index "work_orders", ["store_id"], :name => "index_work_orders_on_store_id"

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
    t.float    "gas_num"
    t.integer  "store_id"
  end

  add_index "work_records", ["created_at"], :name => "index_work_records_on_created_at"
  add_index "work_records", ["current_day"], :name => "index_work_records_on_current_day"
  add_index "work_records", ["staff_id"], :name => "index_work_records_on_staff_id"

end
