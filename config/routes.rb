LantanBAM::Application.routes.draw do

  resources :syncs do
    get "upload_file"
    collection do
      post "upload_image"
    end
  end
  
  resources :package_cards do
    member do
      post :delete_pcard
    end
  end
  resources :stations do
    collection do
      get "simple_station"
    end
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.
  root :to => 'logins#index'
  resources :logins do
    collection do
      get "logout"
    end
  end
  match "logout" => "logins#logout"
  resources :stores do
    resources :market_manages do
      collection do
        get "makets_totals","makets_list","makets_reports","makets_views","makets_goal",
          "sale_orders","sale_order_list","stored_card_record","daily_consumption_receipt",
          "stored_card_bill", "daily_consumption_receipt_blank", "stored_card_bill_blank"
        post "search_month","search_report","search_sale_order"
      end
    end
    resources :complaints do
      collection do
        post "search","search_degree","detail_s"
        get "search_list","show_detail","satisfy_degree","degree_list","detail_list"
      end
    end
    resources :stations do
      collection do
        get "show_detail","show_video","see_video","search_video"
        post "search"
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
        post "pcard_types","add_pcard","search"
        get "sale_records","search_list"
      end
      member do
        post "edit_pcard","update_pcard"
      end
    end
    resources :products do
      collection do
        post "edit_prod","add_prod","add_serv","serv_create","load_material"
        get "prod_services"
      end
      member do
        post "edit_prod","update_prod","serv_update","edit_serv","show_prod","show_serv","serve_delete","prod_delete"
      end
    end
    resources :materials do
      collection do
        get "out","search","order","page_materials","search_head_orders","search_supplier_orders","alipay",
          "print","cuihuo","cancel_order","page_outs","page_ins","page_head_orders","page_supplier_orders",
          "search_supplier_orders","receive_order","pay_order","update_notices","check_nums","material_order_pay"
        post "out_order","material_order","add","alipay_complete","add_material","batch_check"
      end
      member do
        get "mat_order_detail","get_remark"
        post "remark"
      end
    end

    resources :staffs
    resources :violation_rewards
    resources :trains
    resources :month_scores do
      collection do
        get "update_sys_score"
      end
    end
    resources :salaries
    resources :current_month_salaries
    resources :material_order_manages
    resources :staff_manages do
      collection do
        get "get_year_staff_hart"
        get "average_score_hart"
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
    resources :welcomes
    resources :customers do
      collection do
        post "search", "customer_mark", "single_send_message"
        get "search_list"
      end
      member do
        get "order_prods", "revisits", "complaints"
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

    
    resources :station_datas
  end
  resources :materials_in_outs
  match 'stores/:id/materials_in' => 'materials_in_outs#materials_in'
  match 'stores/:id/materials_out' => 'materials_in_outs#materials_out'
  match 'get_material' => 'materials_in_outs#get_material'
  match 'create_materials_in' => 'materials_in_outs#create_materials_in'
  match 'create_materials_out' => 'materials_in_outs#create_materials_out'
  match 'save_cookies' => 'materials_in_outs#save_cookies'
  match 'stores/:store_id/materials/:mo_id/get_mo_remark' => 'materials#get_mo_remark'
  match 'stores/:store_id/materials/:mo_id/order_remark' => 'materials#order_remark'
  match 'stores/:store_id/uniq_mat_code' => 'materials#uniq_mat_code'
  match '/upload_code' => 'materials_in_outs#upload_code'
  match '/upload_checknum' => 'materials#upload_checknum'
  resources :customers do
    collection do
      post "get_car_brands", "get_car_models", "check_car_num", "check_e_car_num"
      get "show_revisit_detail"
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

  namespace :api do
    resources :orders do
      collection do
        post "login","add","pay","complaint","search_car","send_code","index_list","brands_products","finish",
          "confirm_reservation","refresh","pay_order","checkin", "show_car"
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
  end

end