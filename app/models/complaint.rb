#encoding: utf-8
class Complaint < ActiveRecord::Base
  has_many :revisits
  belongs_to :order
  belongs_to :customer
  has_many :store_complaints
  has_many :store_pleasants
  require 'rubygems'
  require 'google_chart'
  require 'net/https'
  require 'uri'
  require 'open-uri'

  #投诉类型
  TYPES = { :WASH => 1, :WAXING=> 2, :DIRT => 3, :INNER_WASH => 4, :INNER_WAXING => 5, :POLISH => 6, :SILVER => 7, :GLASS => 8,
    :ACCIDENT => 9, :TECHNICIAN => 10, :SERVICE => 11,:ADVISER => 12, :REST => 13, :BAD => 14, :PART => 15, :TIMEOUT => 16,
    :LONG_WAIT => 16, :INVALID => 17}
         
  TYPES_NAMES = {1 => "精洗施工质量", 2 => "打蜡施工质量", 3 => "去污施工质量", 4 => "内饰清洗施工质量", 5 => "内饰护理施工质量",
    6 => "抛光施工质量", 7 => "镀晶施工质量", 8 => "玻璃清洗护理施工质量", 9 => "施工事故（施工过程中导致车辆受损）",
    10 => "美容技师服务态度不好", 11 => "服务顾问服务态度不好",
    12 => "服务顾问着装或言辞不得体",13 => "休息厅自取茶水或报纸杂志等不完备", 14 => "休息厅环境差",
    15 => "展厅体验不完整", 16 => "施工等待时间过长", 17 => "无效投诉"}
  CHART_NAMES = {1=>"精洗",2=>"打蜡",3=>"去污",4=>"内饰清洗",5=>"内饰护理",6=>"抛光",7=>"踱晶",8=>"玻璃清洗护理",9=>"施工事故",
    10=>"美容技师服务",11=>"服务顾问服务",12=>"服务顾问着装",13=>"休息厅设备不完善",14=>"休息厅环境差",15=>"展厅体验",16=>"等待时间过长",
    17=>"无效投诉"}

  #投诉状态
  STATUS = {:UNTREATED => 0, :PROCESSED => 1} #0 未处理  1 已处理
  STATUS_NAME ={0=>"未处理",1=>"已处理"}
  VIOLATE = {:NORMAL=>1,:INVALID=>0} #0  不纳入  1 纳入
  VIOLATE_N = {true=>"是",false=>"否"}


  def self.one_customer_complaint(store_id, customer_id, per_page, page)
    return Complaint.paginate_by_sql(["select c.id c_id, c.created_at, c.reason, c.suggestion, c.types, c.status, c.remark,
          st.name st_name1, st2.name st_name2, o.code, o.id o_id from complaints c
          left join orders o on o.id = c.order_id 
          left join staffs st on st.id = c.staff_id_1 left join staffs st2 on st2.id = c.staff_id_2
          where c.store_id = ? and c.customer_id = ? ", store_id, customer_id],
      :per_page => per_page, :page => page)
  end

  def self.count_types(store_id)
    return Complaint.find_by_sql("select count(*) total_num,types from complaints where store_id=#{store_id} and
           date_format(created_at,'%Y-%m')=date_format(DATE_SUB(curdate(), INTERVAL 1 MONTH),'%Y-%m') group by types")
  end
  
  def self.gchart(store_id)
    coplaint = Complaint.count_types(store_id).inject(Hash.new) {|panel,complaint| panel[complaint.types]=complaint.total_num;panel}
    month = Complaint.get_chart(store_id)
    unless coplaint.keys.blank?
      size =(0..10).inject(Array.new){|arr,int| arr << (coplaint.values.max%10==0 ? coplaint.values.max/10 : coplaint.values.max/10+1)*int} #生成图表的y的坐标
      GoogleChart::BarChart.new('1000x300', "#{Time.now.months_ago(1).strftime('%Y-%m')}投诉情况分类表", :vertical, false) do |bc|
        bc.data "Trend 2", coplaint.values, 'ff0000'
        bc.width_spacing_options :bar_width => 15, :bar_spacing => (1000-(15*coplaint.keys.length))/coplaint.keys.length,
          :group_spacing =>(1000-(15*coplaint.keys.length))/coplaint.keys.length
        bc.max_value size.max
        bc.axis :x, :labels => coplaint.keys.inject(Array.new) {|pal,key| pal << Complaint::CHART_NAMES[key] }
        bc.axis :y, :labels =>size
        bc.grid :x_step => 3.333, :y_step => 10, :length_segment => 1, :length_blank => 3
        img_url = write_img(URI.escape(URI.unescape(bc.to_url)),store_id,ChartImage::TYPES[:COMPLAINT],store_id)
        month=ChartImage.create({:store_id=>store_id,:types =>ChartImage::TYPES[:COMPLAINT],:created_at => Time.now, :image_url => img_url, :current_day => Time.now.months_ago(1)}) if month.blank?
      end
    end
    return month
  end

  def self.get_chart(store_id)
    return ChartImage.first(:conditions=>"store_id=#{store_id} and
   date_format(current_day,'%Y-%m')=date_format(DATE_SUB(curdate(), INTERVAL 1 MONTH),'%Y-%m') and types=#{ChartImage::TYPES[:COMPLAINT]}")
  end

  def self.search_lis(store_id,created_at)
    sql ="select * from chart_images where store_id=#{store_id} and types=#{ChartImage::TYPES[:COMPLAINT]}"
    sql += " and date_format(current_day,'%Y-%m')=date_format('#{created_at}','%Y-%m') order by created_at desc"  unless created_at=="" || created_at.length==0
    return ChartImage.find_by_sql(sql)[0]
  end


  def self.degree_chart(store_id)
    month = Complaint.count_pleasant(store_id)
    sql="select count(*) num,is_pleased,month(created_at) day from orders where date_format(created_at,'%Y-%m')< date_format(now(),'%Y-%m')
     and store_id=#{store_id}  group by month(created_at),is_pleased"
    orders=Order.find_by_sql(sql).inject(Hash.new){|hash,pleased|   
      hash[pleased.day].nil? ? hash[pleased.day]={pleased.is_pleased=>pleased.num} : hash[pleased.day].merge!({pleased.is_pleased=>pleased.num});hash}
    unless orders=={}
      percent ={}
      orders.each {|k,order| percent[k]=(order[true].nil? ? 0 : order[true]*100)/(order.values.inject(0){|num,level| num+level})}
      lc = GoogleChart::LineChart.new('1000x300', "满意度月度统计表", true)
      lc.data "满意度",percent.inject(Array.new){|arr,o|arr << [o[0]-1,o[1]]} , 'ff0000'
      size =(0..10).inject(Array.new){|arr,int| arr << (percent.values.max%10==0 ? percent.values.max/10 : percent.values.max/10+1)*int} #生成图表的y的坐标
      lc.max_value [orders.keys.length-1,percent.values.max]
      lc.axis :x, :labels =>orders.keys.inject(Array.new){|arr,mon|arr << "#{mon}月"}
      lc.axis :y, :labels => size
      lc.grid :x_step => 3.333, :y_step => 10, :length_segment => 1, :length_blank => 3
      img_url=write_img(URI.escape(URI.unescape(lc.to_url({:chm => "o,0066FF,0,-1,6"}))),store_id,ChartImage::TYPES[:SATIFY],store_id)
      month = ChartImage.create({:store_id=>store_id,:types =>ChartImage::TYPES[:SATIFY],:created_at => Time.now, :image_url => img_url, :current_day => Time.now.months_ago(1)})  if month.blank?
    end
    return month
  end

  def self.count_pleasant(store_id)
    return ChartImage.first(:conditions=>"store_id=#{store_id} and types=#{ChartImage::TYPES[:SATIFY]} and
   date_format(current_day,'%Y-%m')=date_format(DATE_SUB(curdate(), INTERVAL 1 MONTH),'%Y-%m')")
  end

  def self.degree_lis(store_id,created_at)
    sql ="select * from chart_images where store_id=#{store_id} and types=#{ChartImage::TYPES[:SATIFY]}"
    sql += " and date_format(current_day,'%Y-%m')=date_format('#{created_at}','%Y-%m') order by created_at desc"  unless created_at=="" || created_at.length==0
    return ChartImage.find_by_sql(sql)[0]
  end

  def self.search_detail(store_id,page)
    return Complaint.paginate_by_sql("select c.*,o.code,o.id o_id from complaints c inner join orders o on o.id=c.order_id
    where c.store_id=#{store_id} and date_format(now(),'%Y-%m')=date_format(c.created_at,'%Y-%m') order by created_at desc", :page => page, :per_page => 15)
  end

  def self.search_non(store_id,num=nil)
    sql ="select count(*) num from complaints  where store_id=#{store_id} and date_format(created_at,'%Y-%m')=date_format(now(),'%Y-%m')"
    sql += " and TO_DAYS(process_at)=TO_DAYS(created_at)"  if num==0
    sql += " and process_at is null " if num==1
    return Complaint.find_by_sql(sql)[0]
  end

  def self.search_one(store_id,time,num=nil)
    sql ="select count(*) num from complaints  where store_id=#{store_id} "
    sql += "and date_format(created_at,'%Y-%m')=date_format('#{time}','%Y-%m')" unless time =="" || time.length==0
    sql += " and TO_DAYS(process_at)=TO_DAYS(created_at)"  if num==0
    sql += " and process_at is null " if num==1
    return Complaint.find_by_sql(sql)[0]
  end

  def self.detail_one(store_id,page,time)
    sql ="select c.*,o.code,o.id o_id from complaints c inner join orders o on o.id=c.order_id where c.store_id=#{store_id} "
    sql += "and date_format(c.created_at,'%Y-%m')=date_format('#{time}','%Y-%m')" unless time =="" || time.length==0
    sql += " order by created_at desc"
    return Complaint.paginate_by_sql(sql, :page => page, :per_page => 15)
  end

  def self.mk_record store_id ,order_id,reason,request

    #puts store_id ,order_id,reason,request
    order  = Order.find_by_id order_id
    complaint = Complaint.create(:order_id => order_id, :customer_id => order.customer_id, :reason => reason,
      :suggestion => request, :status => STATUS[:UNTREATED]) if order
    complaint
  end

  def self.write_img(url,store_id,types,object_id)  #上传图片
    file_name ="#{Time.now.strftime("%Y%m%d").to_s}_#{object_id}.jpg"
    dir = "#{File.expand_path(Rails.root)}/public/chart_images"
    Dir.mkdir(dir) unless File.directory?(dir)
    total_dir ="#{dir}/#{store_id}/"
    Dir.mkdir(total_dir) unless File.directory?(total_dir)
    all_dir ="#{total_dir}/#{types}/"
    Dir.mkdir(all_dir) unless File.directory?(all_dir)
    file_url ="#{all_dir}#{file_name}"
    open(url) do |fin|
      File.open(file_url, "wb+") do |fout|
        while buf = fin.read(1024) do
          fout.write buf
        end
      end
    end
    return "/chart_images/#{store_id}/#{types}/#{file_name}"
    puts "Chart #{object_id} success generated"
  end
end
