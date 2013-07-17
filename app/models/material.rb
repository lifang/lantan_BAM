#encoding: utf-8
require 'barby'
require 'barby/barcode/code_128'
require 'barby/barcode/ean_13'
require 'barby/outputter/custom_rmagick_outputter'
require 'barby/outputter/rmagick_outputter'
class Material < ActiveRecord::Base
  has_many :prod_mat_relations
  has_many :mat_order_items
  has_many :material_orders, :through => :mat_order_items do 
    def not_all_in
       where("m_status not in (?) and status != ?",[3,4], MaterialOrder::STATUS[:cancel])
    end
  end
  has_many :mat_out_orders
  has_many  :mat_in_orders
  has_many :prod_mat_relations
  has_many :mat_depot_relations
  has_many :depots, :through => :mat_depot_relations
  before_create :generate_barcode
  after_create :generate_barcode_img

  STATUS = {:NORMAL => 0, :DELETE => 1}
  TYPES_NAMES = {0 => "清洁用品", 1 => "美容用品", 2 => "装饰产品", 3 => "配件产品", 4 => "电子产品",
    5 =>"其他产品",6 => "辅助工具", 7 => "劳动保护"}
  TYPES = { :CLEAN_PROD =>0, :BEAUTY_PROD =>1,:DECORATE_PROD =>2, :ACCESSORY_PROD =>3, :ELEC_PROD =>4,
    :OTHER_PROD => 5, :ASSISTANT_TOOL => 6, :LABOR_PROTECT => 7}
  PRODUCT_TYPE = [TYPES[:CLEAN_PROD], TYPES[:BEAUTY_PROD], TYPES[:DECORATE_PROD],
    TYPES[:ACCESSORY_PROD], TYPES[:ELEC_PROD], TYPES[:OTHER_PROD]]
  MAT_IN_PATH = "#{File.expand_path(Rails.root)}/public/uploads/mat_in/%s"
  MAT_OUT_PATH = "#{File.expand_path(Rails.root)}/public/uploads/mat_out/%s"
  MAT_CHECKNUM_PATH = "#{File.expand_path(Rails.root)}/public/uploads/mat_check/%s"
  IS_IGNORE = {:YES => 1, :NO => 0} #是否忽略库存预警， 1是 0否
  DEFAULT_MATERIAL_LOW = 0    #默认库存预警为0
  scope :normal, where(:status => STATUS[:NORMAL])

  def self.unsalable_list page,per_page,store_id,sql=[nil,nil,nil,nil]
    Material.find_by_sql("select * from materials m where m.id not in(select material_id as id from mat_out_orders where
    #{sql[0]} and #{sql[1]} and store_id = '#{store_id}' group by material_id having #{sql[2]} order by material_id) and m.status !=#{Material::STATUS[:DELETE]} and m.store_id = '#{store_id}' and #{sql[3]};").
        paginate(:page => page, :per_page => per_page)
  end

  private
  
  def generate_barcode
    #self.code = types.to_s + Time.now.strftime("%Y%m%d%H%M%S")
    self.code = '123456789012'
  end

  def generate_barcode_img
    #barcode = Barby::Code128B.new(self.code)
    barcode = Barby::EAN13.new(self.code)
    if !FileTest.directory?("#{File.expand_path(Rails.root)}/public/barcode/#{self.id}")
      FileUtils.mkdir_p "#{File.expand_path(Rails.root)}/public/barcode/#{self.id}"
    end
    barcode.to_image_with_data(:height => 350, :margin => 10, :xdim => 7).write(Rails.root.join('public', "barcode", "#{self.id}", "barcode.png"))
    #self.update_attribute(:code_img, "/barcode/#{self.id}/barcode.png")

#    file_path = "#{File.expand_path(Rails.root)}/public/barcode/#{self.id}/barcode.png"
#    img = MiniMagick::Image.open file_path,"rb"
#
#    [748].each do |size|
#      resize = size
#      new_file = file_path.split(".")[0]+"_#{resize}."+file_path.split(".").reverse[0]
#      resize_file_name = "barcode"+"_#{resize}."+"png"
#      self.update_attribute(:code_img, "/barcode/#{self.id}/#{resize_file_name}")
#      img.run_command("convert #{file_path}  -resize #{resize}x#{resize} #{new_file}")
#    end

  end
end
