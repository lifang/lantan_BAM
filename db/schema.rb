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

ActiveRecord::Schema.define(:version => 20130228015440) do

  create_table "c_pcard_relations", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "package_card_id"
    t.datetime "ended_at"
    t.boolean  "status"
    t.text     "content"
    t.datetime "created_at"
  end

  create_table "c_svc_relations", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "sv_card_id"
    t.float    "total_price"
    t.float    "left_price"
    t.string   "id_card"
    t.datetime "created_at"
  end

  create_table "capitals", :force => true do |t|
    t.string "name"
  end

  create_table "car_brands", :force => true do |t|
    t.string  "name"
    t.integer "capital_id"
  end

  create_table "car_models", :force => true do |t|
    t.string  "name"
    t.integer "car_brand_id"
  end

  create_table "car_nums", :force => true do |t|
    t.string  "num"
    t.integer "car_model_id"
    t.integer "buy_year"
  end

  create_table "cities", :force => true do |t|
    t.string  "name"
    t.integer "parent_id"
  end

  create_table "complaints", :force => true do |t|
    t.integer  "order_id"
    t.text     "reason"
    t.text     "suggstion"
    t.text     "remark"
    t.boolean  "status",       :default => false
    t.integer  "types"
    t.integer  "staff_id_1"
    t.integer  "staff_id_2"
    t.datetime "process_at"
    t.boolean  "is_violation"
    t.integer  "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "store_id"
  end

  create_table "customer_num_relations", :force => true do |t|
    t.integer "customer_id"
    t.integer "car_num_id"
  end

  create_table "customers", :force => true do |t|
    t.string   "name"
    t.string   "mobilephone"
    t.string   "other_way"
    t.boolean  "sex"
    t.datetime "birthday"
    t.string   "address"
    t.boolean  "is_vip",      :default => false
    t.string   "mark"
    t.boolean  "status",      :default => false
    t.integer  "types"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "goal_sales", :force => true do |t|
    t.datetime "started_at"
    t.datetime "ended_at"
    t.string   "type_name"
    t.float    "goal_price"
    t.float    "current_price"
    t.integer  "store_id"
    t.datetime "created_at"
  end

  create_table "m_order_types", :force => true do |t|
    t.integer "material_order_id"
    t.integer "pay_types"
    t.float   "price"
  end

  create_table "mat_in_orders", :force => true do |t|
    t.integer  "material_order_id"
    t.integer  "material_id"
    t.integer  "material_num"
    t.float    "price"
    t.integer  "staff_id"
    t.datetime "created_at"
  end

  create_table "mat_order_items", :force => true do |t|
    t.integer "material_order_id"
    t.integer "material_id"
    t.integer "material_num"
    t.float   "price"
  end

  create_table "mat_out_orders", :force => true do |t|
    t.integer  "material_id"
    t.integer  "staff_id"
    t.integer  "material_num"
    t.float    "price"
    t.integer  "material_order_id"
    t.datetime "created_at"
  end

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
    t.integer  "sale_id"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.string   "remark",     :limit => 1000
    t.integer  "check_num",                  :default => 0
  end

  create_table "menus", :force => true do |t|
    t.string "controller"
  end

  create_table "message_records", :force => true do |t|
    t.string   "content"
    t.datetime "send_at"
    t.boolean  "status",     :default => false
    t.integer  "store_id"
    t.datetime "created_at"
  end

  create_table "models", :force => true do |t|
    t.string  "name"
    t.integer "num"
  end

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
  end

  create_table "order_pay_types", :force => true do |t|
    t.integer "order_id"
    t.integer "pay_type"
    t.float   "price"
  end

  create_table "order_prod_relations", :force => true do |t|
    t.integer "order_id"
    t.integer "product_id"
    t.integer "pro_num"
    t.float   "price"
  end

  create_table "orders", :force => true do |t|
    t.string   "code"
    t.integer  "car_num_id"
    t.boolean  "status"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.float    "price"
    t.boolean  "is_visited"
    t.boolean  "is_pleased"
    t.boolean  "is_billing"
    t.integer  "front_staff_id"
    t.integer  "cons_staff_id_1"
    t.string   "cons_staff_id_2"
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
  end

  create_table "pcard_prod_relations", :force => true do |t|
    t.integer "product_id"
    t.integer "product_num"
    t.integer "package_card_id"
  end

  create_table "prod_mat_relations", :force => true do |t|
    t.integer "product_id"
    t.integer "material_num"
    t.integer "material_id"
  end

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
  end

  create_table "res_prod_relations", :force => true do |t|
    t.integer "product_id"
    t.integer "reservation_id"
  end

  create_table "reservations", :force => true do |t|
    t.integer  "car_num_id"
    t.datetime "res_time"
    t.boolean  "status"
    t.integer  "store_id"
    t.datetime "created_at"
  end

  create_table "revisit_order_relations", :force => true do |t|
    t.integer "revisit_id"
    t.integer "order_id"
  end

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
    t.integer "role_id"
    t.integer "menu_id"
  end

  create_table "role_model_relations", :force => true do |t|
    t.integer "role_id"
    t.integer "num"
    t.string  "model_name"
  end

  create_table "roles", :force => true do |t|
    t.string "name"
  end

  create_table "salaries", :force => true do |t|
    t.integer  "deduct_num"
    t.integer  "reward_num"
    t.float    "total"
    t.integer  "current_month"
    t.integer  "staff_id"
    t.integer  "satisfied_perc"
    t.datetime "created_at"
    t.boolean  "status",         :default => false
  end

  create_table "salary_details", :force => true do |t|
    t.integer  "current_day"
    t.integer  "deduct_num"
    t.integer  "reward_num"
    t.float    "satisfied_perc"
    t.integer  "staff_id"
    t.integer  "voilation_reward_id"
    t.datetime "created_at"
  end

  create_table "sale_prod_relations", :force => true do |t|
    t.integer "sale_id"
    t.integer "product_id"
    t.integer "prod_num"
  end

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
  end

  create_table "send_messages", :force => true do |t|
    t.integer  "message_record_id"
    t.text     "content"
    t.integer  "customer_id"
    t.string   "phone"
    t.datetime "send_at"
    t.boolean  "status"
  end

  create_table "staff_gr_records", :force => true do |t|
    t.integer  "staff_id"
    t.integer  "level"
    t.integer  "base_salary"
    t.integer  "deduct_at"
    t.integer  "deduct_end"
    t.float    "deduct_percent"
    t.datetime "created_at"
  end

  create_table "staff_role_relations", :force => true do |t|
    t.integer "role_id"
    t.integer "staff_id"
  end

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
    t.boolean  "status"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password"
    t.string   "username"
    t.string   "salt"
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
  end

  create_table "stations", :force => true do |t|
    t.integer  "status"
    t.integer  "store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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
  end

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

  create_table "sv_cards", :force => true do |t|
    t.string   "name"
    t.string   "img_url"
    t.integer  "types"
    t.integer  "price"
    t.float    "discount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "svc_return_records", :force => true do |t|
    t.integer  "store_id"
    t.float    "price"
    t.integer  "types"
    t.text     "content"
    t.integer  "target_id"
    t.float    "total_price"
    t.datetime "created_at"
  end

  create_table "svcard_prod_relations", :force => true do |t|
    t.integer "product_id"
    t.integer "product_num"
    t.integer "sv_card_id"
  end

  create_table "svcard_use_records", :force => true do |t|
    t.integer  "c_svc_relation_id"
    t.integer  "types"
    t.float    "use_price"
    t.float    "left_price"
    t.datetime "created_at"
  end

  create_table "train_staff_relations", :force => true do |t|
    t.integer "train_id"
    t.integer "staff_id"
    t.boolean "status"
  end

  create_table "trains", :force => true do |t|
    t.string   "content"
    t.datetime "start_at"
    t.datetime "end_at"
    t.boolean  "certificate"
    t.datetime "created_at"
  end

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
  end

  create_table "w_o_times", :force => true do |t|
    t.integer  "current_time"
    t.integer  "current_day"
    t.integer  "station_id"
    t.integer  "worked_num"
    t.integer  "wait_num"
    t.datetime "created_at"
  end

  create_table "work_orders", :force => true do |t|
    t.integer  "station_id"
    t.integer  "status"
    t.integer  "order_id"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer  "current_day"
    t.integer  "runtime"
    t.integer  "violation_num"
    t.string   "violation_reason"
    t.integer  "water_num"
    t.integer  "electricity_num"
    t.integer  "store_id"
    t.datetime "created_at"
  end

  create_table "work_records", :force => true do |t|
    t.integer  "current_day"
    t.integer  "attendance_num"
    t.integer  "construct_num"
    t.integer  "materials_used_num"
    t.integer  "materials_consume_num"
    t.integer  "water_num"
    t.integer  "elec_num"
    t.integer  "complaint_num"
    t.integer  "train_num"
    t.integer  "violation_num"
    t.integer  "reward_num"
    t.integer  "staff_id"
    t.datetime "created_at"
  end

end
