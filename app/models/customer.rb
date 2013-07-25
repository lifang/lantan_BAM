#encoding: utf-8
class Customer < ActiveRecord::Base
  has_many :customer_num_relations
  has_many :c_svc_relations
  has_many :c_pcard_relations
  has_many :revisits
  has_many :send_messages
  has_many :c_svc_relations
  has_many :reservations
  has_many :customer_store_relations
  has_many :stores, :through => :customer_store_relations

  attr_accessor :password
  validates :password, :allow_nil => true, :length =>{:within=>6..20, :message => "密码长度必须在6-20位之间"}

  #客户状态
  STATUS = {:NOMAL => 0, :DELETED => 1} #0 正常  1 删除
  #客户类型
  IS_VIP = {:NORMAL => 0, :VIP => 1} #0 常态客户 1 会员卡客户
  TYPES = {:GOOD => 0, :NORMAL => 1, :STRESS => 2} #1 优质客户  2 一般客户  3 重点客户
  C_TYPES = {0 => "优质客户", 1 => "一般客户", 2 => "重点客户"}


  def self.search_customer(c_types, car_num, started_at, ended_at, name, phone, is_vip, page, store_id)
    base_sql = "select DISTINCT(cu.id), cu.name, cu.mobilephone, csr.is_vip, cu.mark from customers cu
        left join customer_num_relations cnr on cnr.customer_id = cu.id
        left join car_nums ca on ca.id = cnr.car_num_id "
    condition_sql = "where cu.status = #{STATUS[:NOMAL]} "
    params_arr = [""]
    unless c_types.nil? or c_types == "-1"
      condition_sql += " and cu.types = ? "
      params_arr << c_types.to_i
    end
    unless name.nil? or name.strip.empty?
      condition_sql += " and cu.name like ? "
      params_arr << "%#{name.strip}%"
    end
    unless phone.nil? or phone.strip.empty?
      condition_sql += " and cu.mobilephone = ? "
      params_arr << phone.strip
    end
    unless is_vip.nil? or is_vip.strip.empty?
      base_sql += " inner join customer_store_relations csr on csr.customer_id = cu.id "
      condition_sql += " and csr.store_id = ? "
      params_arr << store_id.to_i
      condition_sql += " and csr.is_vip = ? "
      params_arr << is_vip.to_i
    else
      base_sql += " left join customer_store_relations csr on csr.customer_id = cu.id "
      condition_sql += " and csr.store_id in(?) "
      params_arr << StoreChainsRelation.return_chain_stores(store_id)
    end
    unless car_num.nil? or car_num.strip.empty?
      condition_sql += " and ca.num like ? "
      params_arr << "%#{car_num.strip}%"
    end
    is_has_order = false
    need_group_by = false
    unless started_at.nil? or started_at.strip.empty?
      is_has_order = true
      need_group_by = true
      base_sql += " inner join orders o on o.car_num_id = ca.id "
      condition_sql += " and o.created_at >= ? "
      params_arr << started_at.strip
    end
    unless ended_at.nil? or ended_at.strip.empty?
      need_group_by = true
      base_sql += " inner join orders o on o.car_num_id = ca.id " unless is_has_order
      condition_sql += " and o.created_at <= ?"
      params_arr << ended_at.strip.to_date + 1.days
    end
    condition_sql += " group by ca.id " if need_group_by
    params_arr[0] = base_sql + condition_sql
    return Customer.paginate_by_sql(params_arr, :per_page => 10, :page => page)
  end

  def self.auto_generate_customer_type
    stress_customer_ids = []
    Complaint.where("created_at >= '#{Time.now.years_ago(1)}'").each do |complaint|
      customer = complaint.customer
      stress_customer_ids << customer.id and customer.update_attribute(:types, Customer::TYPES[:STRESS]) if customer && !customer.status
    end

    orders = Order.includes(:car_num => {:customer_num_relation => :customer}).
      where("orders.created_at >= '#{Time.now.years_ago(1)}'").
      where("orders.status = #{Order::STATUS[:BEEN_PAYMENT]} || orders.status = #{Order::STATUS[:FINISHED]}").
      where("customers.id not in (?)", stress_customer_ids).
      group_by{|s|s.car_num.customer_num_relation.customer.id}

    result = {}
    orders.each do |key, value|
      result[key] = value.length
    end

    Customer.where("status = #{STATUS[:NOMAL]} and id not in (?)", stress_customer_ids).each do |customer|
      if result.keys.include?(customer.id)
        types = result[customer.id] >= 12 ? Customer::TYPES[:GOOD] : Customer::TYPES[:NORMAL]
        customer.update_attribute(:types, types)
      else
        customer.update_attribute(:types, Customer::TYPES[:NORMAL])
      end
    end
  end

  def Customer.create_single_cus(customer, carnum, phone, car_num, user_name, other_way,
      birth, buy_year, car_model_id, sex, address, is_vip, store_id)
    Customer.transaction do
      if customer.nil?
        customer = Customer.create(:name => user_name, :mobilephone => phone,
          :other_way => other_way, :birthday => birth, :status => Customer::STATUS[:NOMAL],
          :types => Customer::TYPES[:NORMAL], :is_vip => is_vip, :username => user_name,
          :password => phone, :sex => sex, :address => address)
        customer.encrypt_password
        customer.save        
      end
      relation = CustomerStoreRelation.find_by_store_id_and_customer_id(store_id, customer.id)
      CustomerStoreRelation.create(:store_id => store_id, :customer_id => customer.id) unless relation
      if carnum
        carnum.update_attributes(:buy_year => buy_year, :car_model_id => car_model_id)
      else
        carnum = CarNum.create(:num => car_num, :buy_year => buy_year,
          :car_model_id => car_model_id)
      end
      CustomerNumRelation.delete_all(["car_num_id = ?", carnum.id])
      CustomerNumRelation.create(:car_num_id => carnum.id, :customer_id => customer.id)
    end 
    return [customer, carnum]
  end

  def Customer.customer_car_num(customer_ids)
    car_nums = CarNum.find_by_sql(["select cn.num, cnr.customer_id from car_nums cn
      inner join customer_num_relations cnr on cnr.car_num_id = cn.id where cnr.customer_id in (?)", customer_ids])
    return car_nums.blank? ? {} : car_nums.group_by { |i| i.customer_id }
  end

  def has_password?(submitted_password)
		encrypted_password == encrypt(submitted_password)
	end

  def encrypt_password
    self.encrypted_password=encrypt(password)
  end

  #客户使用套餐卡记录，门店后台跟api共用
  def pc_card_records_method(store_id)
    #套餐卡记录
    c_pcard_relations_no_paginate = CPcardRelation.find_by_sql(["select p.id, p.name, cpr.content, cpr.ended_at
        from c_pcard_relations cpr
        inner join package_cards p on p.id = cpr.package_card_id
        where cpr.status = ? and cpr.customer_id = ? and p.store_id = ?",
        CPcardRelation::STATUS[:NORMAL], self.id, store_id])
#    c_pcard_relations = c_pcard_relations_no_paginate.paginate(:page => page || 1, :per_page => Constant::PER_PAGE) if page
    already_used_count = {}
    if c_pcard_relations_no_paginate.present?
      c_pcard_relations_no_paginate.each do |r|
        service_infos = r.content.split(",")
        single_car_content = {}
        service_infos.each do |s|
          content_arr = s.split("-")
          single_car_content[content_arr[0].to_i] = [content_arr[1], content_arr[2].to_i] if content_arr.length == 3
        end
        already_used_count[r.id] = single_car_content unless single_car_content.empty?
      end
      pcard_prod_relations = PcardProdRelation.joins(:package_card).find(:all, :conditions => ["package_card_id in (?) and package_cards.store_id = ?", c_pcard_relations_no_paginate, store_id])
      pcard_prod_relations.each do |ppr|
        used_count = ppr.product_num - already_used_count[ppr.package_card_id][ppr.product_id][1] if !already_used_count.empty? and already_used_count[ppr.package_card_id].present? and already_used_count[ppr.package_card_id][ppr.product_id]
        already_used_count[ppr.package_card_id][ppr.product_id][1] = used_count ? used_count : 0 unless already_used_count.empty? or already_used_count[ppr.package_card_id].blank? or already_used_count[ppr.package_card_id][ppr.product_id].nil?
      end
      [already_used_count, c_pcard_relations_no_paginate]
    else
      [{}, []]
    end
  end

  private
  def encrypt(string)
    self.salt = make_salt if new_record?
    secure_hash("#{salt}--#{string}")
  end

  def make_salt
    secure_hash("#{Time.new.utc}--#{password}")
  end

  def secure_hash(string)
    Digest::SHA2.hexdigest(string)
  end

end
