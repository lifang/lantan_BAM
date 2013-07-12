#encoding: utf-8
class Product < ActiveRecord::Base
  has_many :sale_prod_relations
  has_many :res_prod_relations
  has_many :station_service_relations
  has_many :order_prod_relations
  has_many :pcard_prod_relations
  has_many :prod_mat_relations
  has_many :materials, :through => :prod_mat_relations
  has_many :svcard_prod_relations
  has_many :image_urls
  has_many :stations, :through => :station_service_relations
  belongs_to :store
  PRODUCT_TYPES = {0 => "清洁用品", 1 => "美容用品", 2 => "装饰产品", 3 => "配件产品", 4 => "电子产品",5 =>"其他产品",
    6 => "清洗服务", 7 => "维修服务", 8 => "钣喷服务", 9 => "美容服务", 10 => "安装服务", 11 => "其他服务"} #产品类别
  TYPES_NAME = {:OTHER_PROD => 5, :OTHER_SERV => 11}
  PRODUCT_END = 6
  PROD_TYPES = {:PRODUCT =>0, :SERVICE =>1}  #0 为产品 1 为服务
  IS_VALIDATE ={:NO=>0,:YES=>1} #0 无效 已删除状态 1 有效
  REVIST_TIME = [24,48,72,96,120]
  IS_AUTO = {:YES=>1,:NO=>0}
  scope :is_service, where(:is_service => true)
  scope :is_normal, where(:status => true)

  def self.revist_message()
    p Product.update_order_time()
    time =Time.now
    condition = Time.now.strftime("%H").to_i<12 ? "date_format(date_add(orders.created_at, interval 'min(products.revist_time)' hour),'%Y-%m-%d %H') between '#{time.beginning_of_day.strftime('%Y-%m-%d %H')}' and '#{time.strftime('%Y-%m-%d')+" 11"}'" :
      "date_format(date_add(orders.created_at, interval 'min(products.revist_time)' hour),'%Y-%m-%d %H') between '#{Time.now}' and '#{Time.now.end_of_day}'"
    p  Order.joins(:order_prod_relations=>:product).where(condition)

  end


  def self.update_order_time(arr)
    product,pcard =[],[]
    arr[0].each{|arr| product << arr[1]}
    arr[3].each{|arr| pcard << arr[1]}
    hour = (Product.find(product.uniq).map(&:auto_time)|PackageCard.find(pcard.uniq).map(&:auto_time)).compact.min
    return Time.now+(hour.nil? ? 0 : hour.hours)
  end

end
