#encoding: utf-8
class Product < ActiveRecord::Base
  include ApplicationHelper
  require 'net/http'
  require "uri"
  require 'openssl'
  require 'zip/zip'
  require 'zip/zipfilesystem'
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
  belongs_to :category
  PRODUCT_TYPES = {0 => "清洁用品", 1 => "美容用品", 2 => "装饰产品", 3 => "配件产品", 4 => "电子产品",5 =>"其他产品",
    6 => "清洗服务", 7 => "维修服务", 8 => "钣喷服务", 9 => "美容服务", 10 => "安装服务", 11 => "其他服务"} #产品类别
  TYPES_NAME = {:CLEAN_PROD => 0, :BEAUTIFY_PROD => 1, :DECORATE_PROD => 2, :ASSISTANT_PROD => 3,
    :ELEC_PROD => 4,:OTHER_PROD => 5, :OTHER_SERV => 11}
  PRODUCT_END = 6
  BEAUTY_SERVICE = 9
  PROD_TYPES = {:PRODUCT =>0, :SERVICE =>1}  #0 为产品 1 为服务
  IS_VALIDATE ={:NO =>0,:YES =>1} #0 无效 已删除状态 1 有效   是否在pad上显示 0为不显示 1为显示
  SHOW_ON_IPAD ={:NO=>0,:YES=>1} #是否在ipad端显示
  REVIST_TIME = [24,48,72,96,120]
  IS_AUTO = {:YES=>1,:NO=>0}
  IS_ADDED = {:YES=>1,:NO=>0}
  SINGLE_TYPE = {:SIN =>0,:DOUB =>1} #单次服务0 套装 1
  #scope :is_service, joins(:categories).where("categories.types = ?", Category::TYPES[:service])
  scope :is_service, where(:is_service => true)
  scope :is_normal, where(:status => true)
  scope :commonly_used, where(:commonly_used => true)
  PACK_SERVIE  = {0=>"产品套装服务"}
  PACK ={:PACK => 0}


  #根据回访要求发送客户短信，会查询所有的门店信息发送,设置的时间为每天的11:30和8点半左右，每天两次执行
  def self.revist_message()
    store_ids,customer_ids,message_arr = [],[],[]
    condition = Time.now.strftime("%H").to_i<12 ? "date_format(send_messages.send_at,'%Y-%m-%d %H') between '#{Time.now.beginning_of_day.strftime("%Y-%m-%d %H")}'
    and '#{Time.now.strftime('%Y-%m-%d')+" 11"}'" : "date_format(send_messages.send_at,'%Y-%m-%d %H') between '#{Time.now.strftime('%Y-%m-%d')+" 12"}' and '#{Time.now.end_of_day.strftime("%Y-%m-%d %H")}'"
    p send_messages = SendMessage.joins(:store).where(condition+" and auto_send=#{Store::AUTO_SEND[:YES]}").group_by{|i|store_ids << i.store_id;customer_ids << i.customer_id;{:c_id=>i.customer_id,:s_id=>i.store_id}}
    unless send_messages.empty?
      customers = Customer.find(customer_ids).inject({}){|h,c|h[c.id]=c;h}
      stores = Store.find(store_ids).inject({}){|h,s|h[s.id]=s.name;h}
      send_messages.each { |k,v|
        strs = []
        v.each_with_index {|str,index| strs << "#{index+1}.#{str.content}" }
        if customers[k[:c_id]] && stores[k[:s_id]]
          content ="#{customers[k[:c_id]].name}\t女士/男士,您好,#{stores[k[:s_id]]}的美容小贴士提醒您:\n" + strs.join("\r\n")
          message_arr << {:content => content.gsub(/([   ])/,"/t"), :msid => "#{customers[k[:c_id]].id}", :mobile =>customers[k[:c_id]].mobilephone}
        end
      } 
      msg_hash = {:resend => 0, :list => message_arr ,:size => message_arr.length}
      jsondata = JSON msg_hash
      begin
        message_route = "/send_packet.do?Account=#{Constant::USERNAME}&Password=#{Constant::PASSWORD}&jsondata=#{jsondata}&Exno=0"
        message_route
        create_message_http(Constant::MESSAGE_URL, message_route)
        SendMessage.where(condition+" and store_id in (#{store_ids.join(',')})").update_all :status=>SendMessage::STATUS[:FINISHED]
        p "success"
      rescue
        p "error"
        SendMessage.where(condition+" and store_id in (#{store_ids.join(',')})").update_all :status=>SendMessage::STATUS[:FAIL]
      end
    end
  end


  #付款完成生成订单的时候更新订单回访记录
  def self.update_order_time(arr)
    product,pcard =[],[]
    arr[0].each{|arr| product << arr[1]}
    arr[3].each{|arr| pcard << arr[1]}
    hour = (Product.find(product.uniq).map(&:auto_time)|PackageCard.find(pcard.uniq).map(&:auto_time)).compact.min
    day = PackageCard.find(pcard.uniq).map(&:time_warn)
    revist = (Product.find(product.uniq).map(&:revist_content)|PackageCard.find(pcard.uniq).map(&:revist_content)).compact
    warn = PackageCard.find(pcard.uniq).map(&:con_warn).compact
    return [[hour.nil? ? nil : Time.now+hour.hours,day.nil? ? nil : Time.now+day.days],[revist.join(','),warn.join(',')]]  #修改时间条件，如果不需要回访则订单的回访时间设置为null
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

  def self.recgnite_pic(dir,file)
    file_path = dir+file.name
    ext_name = File.extname(file_path)
    base_name = File.basename(file_path, ext_name)
    img = MiniMagick::Image.open file_path,"rb"
    change_path = "#{dir}#{base_name}.tif"
    txt_path = "#{Rails.root}/public/result"
    scale_path = "#{dir}#{base_name}_250.tif"
    img.run_command("convert -compress none -depth 8 -alpha off -colorspace Gray  #{file_path} #{change_path} ")
    img.run_command("convert #{change_path} -scale 50% #{scale_path} ")

    if base_name.to_i ==1
      img.run_command("tesseract #{scale_path} #{txt_path} -psm 6 -l chi_sim")  #识别汉字
      v_file = File.read(txt_path+".txt")
    else
      
      img.run_command("tesseract #{scale_path} #{txt_path} -psm 5")
      v_file = File.read(txt_path+".txt")
      if v_file.length >= 2
        p v_file
        img.run_command("tesseract #{scale_path} #{txt_path} -psm 6")
        v_file = File.read(txt_path+".txt")
      else
        v_file = (v_file | File.read(txt_path+".txt"))[0]
      end
    end
    file = File.open("D:/ss/result.txt","a+")
    file.write(base_name+"--"+6.to_s+"--"+v_file)
    file.close
    p v_file
  end

  def alter_level
    station_ids = self.station_service_relations.map(&:station_id)
    Station.find(station_ids).each {|station|
      products = Product.find(station.station_service_relations.joins(:product).where("status = #{Product::IS_VALIDATE[:YES]}").map(&:product_id).compact.uniq)
      levels = (products.map(&:staff_level) | products.map(&:staff_level_1)).uniq.sort
      station.update_attributes({:staff_level=>levels.min,:staff_level1=>levels[0..(levels.length/2.0)].max   })
    } unless station_ids.blank?
  end

  def self.import_data
    path = "/opt/data/"
    get_dir_list(path).each do |model_name|
      datas = File.readlines(path + model_name)[0].force_encoding("UTF-8").split("#;#")
      model = eval(model_name.split(".")[0].split("_").inject(String.new){|str,name| str + name.capitalize})
      attrits = model.first.attributes.keys
      attrits.delete_at(0)
      total_con = []
      datas.each do |data|
        hash ={}
        cons = data.split(',')
        attrits.each_with_index {|title,index| hash[title] = (cons[index+1].nil? || cons[index+1]=="NULL" )? nil : cons[index+1].force_encoding("UTF-8").gsub("'",'')}
        object = model.new(hash)
        object.store_id = 100014
        total_con << object
      end
      model.import total_con, :timestamps=>false, :on_duplicate_key_update=>attrits
    end
  end


  def self.return_station_status(service_ids, store_id, info, order)
    time_arr = Station.arrange_time store_id, service_ids, order
    if info
      info[:start] = ""
      info[:end] = ""
      info[:station_id] = time_arr[0] || ""
    end
    case time_arr[1]
    when 0
      status = 2 #没工位
    when 1
      status = 1  #有符合工位
    when 2
      status = 3 #多个工位
    when 3
      status = 4 #工位上暂无技师
    end
    return [status,info,time_arr[0],time_arr[2]]
  end
 

end
