#encoding: utf-8
class Product < ActiveRecord::Base
  include ApplicationHelper
  require 'net/http'
  require "uri"
  require 'openssl'
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
  TYPES_NAME = {:CLEAN_PROD => 0, :BEAUTIFY_PROD => 1, :DECORATE_PROD => 2, :ASSISTANT_PROD => 3,
    :ELEC_PROD => 4,:OTHER_PROD => 5, :OTHER_SERV => 11}
  PRODUCT_END = 6
  BEAUTY_SERVICE = 9
  PROD_TYPES = {:PRODUCT =>0, :SERVICE =>1}  #0 为产品 1 为服务
  IS_VALIDATE ={:NO=>0,:YES=>1} #0 无效 已删除状态 1 有效
  REVIST_TIME = [24,48,72,96,120]
  IS_AUTO = {:YES=>1,:NO=>0}
  scope :is_service, where(:is_service => true)
  scope :is_normal, where(:status => true)

  #根据回访要求发送客户短信，会查询所有的门店信息发送,设置的时间为每天的11:30和8点半左右，每天两次执行
  def self.revist_message()
    customer_message ={}
    condition = Time.now.strftime("%H").to_i<12 ? "date_format(orders.auto_time,'%Y-%m-%d %H') between '#{Time.now.beginning_of_day.strftime("%Y-%m-%d %H")}' and '#{Time.now.strftime('%Y-%m-%d')+" 11"}'" :
      "date_format(orders.auto_time,'%Y-%m-%d %H') between '#{Time.now.strftime('%Y-%m-%d')+" 12"}' and '#{Time.now.end_of_day.strftime("%Y-%m-%d %H")}'"
    Order.joins(:order_prod_relations=>:product).where(condition+" and products.is_auto_revist=#{Product::IS_AUTO[:YES]}").select("orders.customer_id,products.revist_content,orders.store_id").each{|mess|
      customer_message["#{mess.store_id}_#{mess.customer_id}"].nil? ? customer_message["#{mess.store_id}_#{mess.customer_id}"]= [mess] : customer_message["#{mess.store_id}_#{mess.customer_id}"] << mess}
    Order.joins(:c_pcard_relations =>:package_card).where(condition+" and package_cards.is_auto_revist=#{Product::IS_AUTO[:YES]}").select("orders.customer_id,package_cards.revist_content,orders.store_id").each{|mess|
      customer_message["#{mess.store_id}_#{mess.customer_id}"].nil? ? customer_message["#{mess.store_id}_#{mess.customer_id}"]= [mess] : customer_message["#{mess.store_id}_#{mess.customer_id}"] << mess}
    unless customer_message.keys.blank?
      store_ids = []
      customer_ids = []
      message_arr = []
      customer_message.keys.each {|mess|store_ids << mess.split("_")[0].to_i;customer_ids << mess.split("_")[1].to_i}
      customers = Customer.joins(:customer_store_relations).select("customers.name,customers.id,mobilephone,customer_store_relations.store_id").where("customers.id in (#{customer_ids.join(',')})").inject(Hash.new){|hash,c|
        if hash[c.store_id].nil? 
          hash[c.store_id]={};hash[c.store_id][c.id]=c
        else
          hash[c.store_id][c.id]=c
        end;hash}
      Store.find(store_ids).each do |store|
        customers[store.id].values.each { |c|
          strs = []
          customer_message["#{store.id}_#{c.id}"].each_with_index {|str,index| strs << "#{index+1}.#{str.revist_content}" }
          MessageRecord.transaction do
            message_record = MessageRecord.create(:store_id =>store.id, :content =>strs.join(),
              :status => MessageRecord::STATUS[:SENDED], :send_at => Time.now)
            content ="#{c.name}\t女士/男士,您好,#{store.name}的美容小贴士提醒您:\n" + strs.join("\r\n")
            p content
            SendMessage.create(:message_record_id => message_record.id, :customer_id => c.id,
              :content => content, :phone => c.mobilephone,
              :send_at => Time.now, :status => MessageRecord::STATUS[:SENDED])
            message_arr << {:content => content.gsub(/([   ])/,"/t"), :msid => "#{c.id}", :mobile => c.mobilephone}
          end
        }
      end
      msg_hash = {:resend => 0, :list => message_arr ,:size => message_arr.length}
      jsondata = JSON msg_hash
      begin
        message_route = "/send_packet.do?Account=#{Constant::USERNAME}&Password=#{Constant::PASSWORD}&jsondata=#{jsondata}&Exno=0"
        message_route
        create_message_http(Constant::MESSAGE_URL, message_route)
        p "success"
      rescue
        p "error"
      end
    end
  end


  #付款完成生成订单的时候更新订单回访记录
  def self.update_order_time(arr)
    product,pcard =[],[]
    arr[0].each{|arr| product << arr[1]}
    arr[3].each{|arr| pcard << arr[1]}
    hour = (Product.find(product.uniq).map(&:auto_time)|PackageCard.find(pcard.uniq).map(&:auto_time)).compact.min
    return hour.nil? ? nil : Time.now+hour.hours  #修改时间条件，如果不需要回访则订单的回访时间设置为null
  end

  def self.create_message_http(url,route)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.port==443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request= Net::HTTP::Get.new(route)
    back_res = http.request(request)
    return JSON back_res.body
  end

  def self.get_dir_list(path)
    #获取目录列表
    list = Dir.entries(path)
    list.delete('.')
    list.delete('..')
    return list
  end

  def self.recgnite_pic
    dir = "#{Rails.root}/public/recongte_pics"
    files = get_dir_list(dir)
    files.each do |file|
      file_path = dir +"/"+file
      ext_name = File.extname(file_path)
      p ext_name
      base_name = File.basename(file_path, ext_name)
      p base_name
      img = MiniMagick::Image.open file_path,"rb"
      change_path = "#{Rails.root}/public/#{base_name}.tif"
      p change_path.to_s
      scale_path = "#{Rails.root}/public/#{base_name}_250.tif"
      txt_path = "#{Rails.root}/public/result"
      img.run_command("convert -compress none -depth 8 -alpha off -colorspace Gray  #{file_path} #{change_path} ")
      img.run_command("convert #{change_path} -scale 250% #{scale_path} ")
      img.run_command("tesseract #{change_path} #{txt_path}")
      p File.read(txt_path+".txt")
    end
  end

 

end
