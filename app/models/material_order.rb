#encoding: utf-8
class MaterialOrder < ActiveRecord::Base
  has_many :mat_order_items
  has_many :mat_out_orders
  has_many  :mat_in_orders
  has_many  :m_order_types
  belongs_to :supplier

  STATUS = {:no_pay => 0, :pay => 1, :cancel => 4}
  M_STATUS = {:no_send => 0, :send => 1, :received => 2, :save_in => 3} #未发货--》已发货 --》已收货 --》已入库
  PAY_TYPES = {:CHARGE => 1,:LICENSE=>2, :CASH => 3, :STORE_CARD => 4}
  PAY_TYPE_NAME = {1 => "订货付费",2=>"授权码", 3 => "现金", 4 => "门店账户扣款"}

  def self.make_order
    status = 0

    status
  end

  def self.material_order_code store_id
    store = store_id.to_s
    if store_id < 10
      store =   "00" + store_id.to_s
    elsif store_id < 100
      store =    "0" + store_id.to_s
    end
    store + Time.now.strftime("%Y%m%d%H%M%S")
  end

  def self.supplier_order_records page, per_page, store_id
    self.paginate(:select => "*", :from => "material_orders", :include => [:supplier, {:mat_order_items => :material}], :conditions => "material_orders.supplier_id != 0 and material_orders.store_id = #{store_id}",
      :order => "material_orders.created_at desc",:page => page, :per_page => per_page)
  end

  def self.head_order_records page, per_page, store_id, status=nil
    sql = status.nil? ? "" : "and material_orders.m_status=#{status}"
    self.paginate(:select => "*", :from => "material_orders", :include => [:mat_order_items => :material],
      :conditions => "material_orders.supplier_id = 0 #{sql} and material_orders.store_id = #{store_id}",
      :order => "material_orders.created_at desc",:page => page, :per_page => per_page)
  end

  def self.search_orders store_id,from_date, to_date, status, supplier_id,page,per_page,m_status
    str = "mo.store_id = #{store_id} "
    if supplier_id == 0
      str += " and mo.supplier_id = 0 "
    else
      str += " and mo.supplier_id != 0 "
    end
    if status
      if status == 0
        str += " and mo.status=#{STATUS[:no_pay]} "
      elsif status == 1
        str += " and mo.status=#{STATUS[:pay]} "
      end
    end
    if m_status
      if m_status == 0
        str += " and mo.m_status=#{M_STATUS[:no_send]} "
      elsif m_status == 1
        str += " and mo.m_status=#{M_STATUS[:send]} "
      elsif m_status == 2
        str += " and mo.m_status=#{M_STATUS[:received]} "
      elsif m_status == 3
        str += " and mo.m_status=#{M_STATUS[:save_in]} "
      end
    end
    if from_date && from_date.length > 0
      str += " and unix_timestamp(date_format(mo.created_at,'%Y-%m-%d')) >= unix_timestamp(date_format('#{from_date}','%Y-%m-%d')) "
    end
    if to_date && to_date.length > 0
      str += " and unix_timestamp(date_format(mo.created_at,'%Y-%m-%d')) <= unix_timestamp(date_format('#{to_date}','%Y-%m-%d')) "
    end
    orders = self.paginate(:select => "mo.*", :from => "material_orders mo", :conditions => str,
      :order => "created_at desc",
      :page => page, :per_page => per_page)
    orders
  end

  def check_material_order_status
    mo_status = []
    self.mat_order_items.group_by{|moi| moi.material_id}.each do |material_id, value|
      mat_order_item = MatOrderItem.find_by_material_id_and_material_order_id(material_id, self.id)
      mat_in_order = MatInOrder.where(:material_id => material_id, :material_order_id => self.id)
      if !mat_in_order.nil?
        if mat_in_order.sum(:material_num) >= mat_order_item.try(:material_num)
          mo_status << true
        else
          mo_status << false
        end
      else
        mo_status << false
      end
    end
    !mo_status.include?(false)
  end

  def transfer_status
    case self.m_status
    when M_STATUS[:no_send]
      "未发货"
    when M_STATUS[:send]
      "已发货"
    when M_STATUS[:received]
      "已收货"
    when M_STATUS[:save_in]
      "已入库"
    else
      "未知"
    end
  end

  def pay_status
    case self.status
    when STATUS[:no_pay]
      "未付款"
    when STATUS[:pay]
      "已付款"
    when STATUS[:cancel]
      "已取消"
    else
      "未知"
    end
  end

  def supplier_name
    if supplier_type==0
      "总部"
    else
      supplier.name
    end
  end

  def svc_use_price
    SvcReturnRecord.find_by_target_id(self.id).try(:price)
  end

  def sale_price
    if self.sale_id
      sale = Sale.find self.sale_id 
      sale.sub_content
    end
  end
end
