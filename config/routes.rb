LantanBAM::Application.routes.draw do

  resources :syncs do
    get "upload_file"
    collection do
      post "upload_image"
    end
  end

  resources :stations do
    collection do
      post "handle_order"
    end
  end
  resources :work_records do
    collection do
      post "adjust_types"
    end
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.
  root :to => 'logins#index'
  resources :logins do
    collection do
      get "logout", "send_validate_code","phone_login","manage_content"
      post "forgot_password","login_phone"
    end
  end
  match "logout" => "logins#logout"
  match "phone_login" => "logins#phone_login"
  match "manage_content" => "logins#manage_content"
  resources :stores do
    #resources :depots
    resources :market_manages do
      collection do
        get "makets_totals","makets_list","makets_reports","makets_views","makets_goal",
          "sale_orders","sale_order_list","stored_card_record","daily_consumption_receipt",
          "stored_card_bill", "daily_consumption_receipt_blank", "stored_card_bill_blank","gross_profit"
        post "search_month","search_report","search_sale_order","search_gross_profit"
        get "load_service","load_product","load_pcard","load_goal","load_over"
      end
    end
    resources :complaints do
      collection do
        post "search","search_degree","detail_s","search_time","degree_time","consumer_search"
        get "search_list","show_detail","satisfy_degree","degree_list","detail_list","date_list","time_list","consumer_list"
        get "con_list","cost_price"
      end
      member do
        get "complaint_detail"
      end
    end
    resources :stations do
      collection do
        get "show_detail","show_video","see_video","search_video", "simple_station"
        post "search","collect_info"
      end
    end
    resources :sales do
      collection do
        post "load_types",:delete_sale,:public_sale
      end
      member do
        post "update_sale"
      end
    end
    resources :package_cards do
      collection do
        post "pcard_types","add_pcard","search","delete_pcard"
        get "sale_records","search_list"
      end
      member do
        post "edit_pcard","update_pcard","request_material"
      end
    end
    resources :products do
      collection do
        post "edit_prod","add_prod","add_serv","serv_create","load_material","update_status","add_package","pack_create","destroy_prod"
        get "prod_services","package_service"
      end
      member do
        post "edit_prod","update_prod","serv_update","edit_serv","show_prod","show_serv","serve_delete","prod_delete","commonly_used",
          "edit_pack","pack_update"
      end
    end
    resources :materials do
      collection do
        get "out","search","order","page_materials","search_head_orders","search_supplier_orders","alipay",
          "print","cuihuo","cancel_order","page_outs","page_ins","page_back_records","page_head_orders","page_supplier_orders",
          "search_supplier_orders","pay_order","update_notices","check_nums","material_order_pay","set_ignore",
          "cancel_ignore","search_materials","page_materials_losses","set_material_low_count_commit","print_code",
          "mat_loss_delete","mat_loss","back_good","back_good_search","back_good_commit", "reflesh_low_materials"
        post "out_order","material_order","add","alipay_complete","mat_in","batch_check","set_material_low_commit","output_barcode",
          "mat_loss_add","modify_code"
      end
      member do
        get "mat_order_detail","get_remark" ,"receive_order","tuihuo","set_material_low_count"
        post "remark"
      end
    end

    resources :staffs do
      collection do
        post "search"
      end
      member do
        post "load_work"
      end
    end
    resources :work_records
    resources :violation_rewards do
      collection do
        post "operate_voilate"
      end
    end
    resources :trains
    resources :month_scores do
      collection do
        get "update_sys_score"
      end
    end
    resources :salaries
    resources :current_month_salaries
    resources :material_order_manages do
      collection do
        get "mat_in_or_out_query", "search_mat_in_or_out","page_ins","page_outs",
          "unsalable_materials","search_unsalable_materials","page_unsalable_materials",
          "page_unsalable_materials"
      end
    end
    resources :staff_manages do
      collection do
        get "get_year_staff_hart"
        get "average_score_hart"
        get "average_cost_detail_summary"
      end
    end

    resources :suppliers do
      member do
        post "change"
      end
      collection do
        get "page_suppliers"
      end
    end
    resources :welcomes do
      collection do
        post "edit_store_name", "update_staff_password"
      end
    end
    resources :customers do
      collection do
        post "search", "customer_mark", "single_send_message", "add_car"
        get "search_list", "add_car_get_datas"
      end
      member do
        get "order_prods", "revisits", "complaints", "sav_card_records", "pc_card_records"
      end
    end
    resources :revisits do
      collection do
        post "search", "process_complaint"
        get "search_list"
      end
    end
    resources :messages do
      collection do
        post "search"
        get "search_list"
      end
    end

    resources :roles do
      collection do
        get "staff"
        post "set_role","reset_role"
      end
    end

    resources :set_functions do
      collection do
        get "market_new", "market_new_commit", "market_edit", "market_edit_commit", "storage_new", "storage_new_commit",
          "storage_edit", "storage_edit_commit", "depart_new", "depart_new_commit", "sibling_depart_new",
          "sibling_depart_new_commit","depart_edit", "depart_edit_commit", "depart_del", "position_new",
          "position_new_commit", "position_edit_commit", "position_del_commit"
      end
    end

    resources :set_stores do
      collection do
        get "select_cities"
      end
    end
    resources :station_datas do
      collection do
        post "create"
      end
    end
    resources :discount_cards do
      collection do
        get  "add_products_search", "edit", "edit_dcard_add_products", "edit_add_products_search"
        post "del_all_dcards"
      end
    end
    resources :save_cards do
      collection do
        post "del_all_scards"
      end
    end
    resources :materials_in_outs

    resources :work_orders do
      collection do
        get "work_orders_status"
      end
    end
  end

  match 'stores/:store_id/manage_content' => 'logins#manage_content'
  match 'stores/:store_id/materials_in' => 'materials_in_outs#materials_in'
  match 'stores/:store_id/materials_out' => 'materials_in_outs#materials_out'
  match 'get_material' => 'materials_in_outs#get_material'
  match 'stores/:store_id/create_materials_in' => 'materials_in_outs#create_materials_in'
  match 'create_materials_out' => 'materials_in_outs#create_materials_out'
  match 'save_cookies' => 'materials_in_outs#save_cookies'
  match 'stores/:store_id/materials/:mo_id/get_mo_remark' => 'materials#get_mo_remark'
  match 'stores/:store_id/materials/:mo_id/order_remark' => 'materials#order_remark'
  match 'stores/:store_id/uniq_mat_code' => 'materials#uniq_mat_code'
  match '/upload_code_matin' => 'materials_in_outs#upload_code_matin'
  match '/upload_code_matout' => 'materials_in_outs#upload_code_matout'
  match '/upload_checknum' => 'materials#upload_checknum'
  match 'stores/:store_id/materials_losses/add' => 'materials_losses#add'
  match 'stores/:store_id/materials_losses/delete' => 'materials_losses#delete'
  match 'stores/:store_id/materials_losses/view' => 'materials_losses#view'
  match 'materials/search_by_code' => 'materials#search_by_code'

  #match 'stores/:store_id/depots' => 'depots#index'
  #match 'stores/:store_id/depots/create' => 'depots#create'
  match 'stores/:store_id/depots' => 'depots#index'
  match 'stores/:store_id/check_mat_num' => 'materials#check_mat_num'
  resources :customers do
    collection do
      post "get_car_brands", "get_car_models", "check_car_num", "check_e_car_num","return_order","operate_order"
      get "show_revisit_detail","print_orders"
    end
    member do
      post "edit_car_num"
      get "delete_car_num"
      
    end
  end

  resources :orders do
    member do
      get "order_info", "order_staff"
    end
  end

  resources :materials do
    member do
      get "check"
    end
    collection do
      get "get_act_count", "out"
    end
  end
  
  resources :work_orders do
    collection do
      post "login"
    end
  end

  namespace :api do
    resources :orders do
      collection do
        post "login","add","pay","complaint","search_car","send_code","index_list","brands_products","finish",
          "confirm_reservation","refresh","pay_order","checkin", "show_car", "sync_orders_and_customer","get_user_svcard",
          "use_svcard","work_order_finished","login_and_return_construction_order","check_num","out_materials",
          "get_construction_order","search_by_car_num2","materials_verification","get_lastest_materails","stop_construction",
          "search_material"
      end
    end
    resources :syncs_datas do
      collection do
        post :syncs_db_to_all, :syncs_pics
      end
      member do
        get :return_sync_all_to_db
      end
    end
    resources :logins do
      collection do
        post :check_staff,:staff_login,:staff_checkin,:upload_img,:recgnite_pic
        get :download_staff_infos
      end
    end
    resources :licenses_plates do
      collection do
        post :upload_file
        get :send_file
      end
    end

    #新的app
    resources :new_app_orders do
      collection do
        post :new_index_list,:make_order, :order_infom, :change_station,:work_order_finished,:order_info, :pay_order
      end
    end

    resources :change do
      collection do
        get :sv_records
        post :change_pwd,:send_code,:use_svcard
      end
    end
  end
  resources :return_backs do
    collection do
      get :return_info, :return_msg, :generate_b_code
    end
  end



end
