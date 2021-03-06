#encoding: utf-8
module Constant
  LOCAL_DIR = "#{Rails.root}/public/"
 
  #权限
  ROLES = {
    #客户
    :customers => {
      :name => "客户",
      :show => ["查询",1],
      :create => ["新建客户",2],
      :detail => ["查看客户详细信息", 4],
      :remark => ["备注", 8],
      :send_msg =>["发短信",16],
      :delete => ["删除客户",32],
      :edit => ["编辑客户基本信息",64],
      :edit_car_num => ["编辑车牌信息",128],
      :delete_car_num => ["删除车牌信息",256],
      :revisit => ["客户详情页面回访",512],
      :deal_complaint => ["处理投诉",1024],
      :revisit_search => ["客户回访查询", 2048],
      :revisit_all => ["客户回访", 4096],
      :message_search => ["群发短信查询", 8192],
      :group_msg => ["群发短信",16384]
    },
    #库存
    :materials => {
      :name => "库存",
      :add => ["添加物料", 1],
      :in => ["入库",2],
      :out => ["出库",4],
      :dinghuo =>["订货",8],
      :check_all =>["批量盘点",16],
      :make_warning =>["设置库存预警",32],
      :print => ["打印库存清单", 64],
      :mat_search => ["库存查询", 128],
      :mat_mark => ["物料备注", 256],
      :check => ["盘点核实",512],
      :ignore => ["忽略库存预警",1024],
      :ignore_cancel => ["取消忽略出库预警", 2048],
      :rk_search => ["入库记录查询", 4096],
      :ck_search => ["出库记录查询", 8192],
      :dh_search => ["向总部订货记录查询", 16384],
      :sup_dh_serch => ["向供应商订货记录查询", 32768],
      :cuihuo => ["催货",65536],
      :cancel => ["取消订单",131072],
      :pay => ["付款",262144],
      :shouhuo => ["确认收货", 524288],
      :tuihuo => ["退货", 1048576],
      :order_mark => ["订货记录备注",2097152],
      :del_supplier => ["删除供应商",4194304],
      :mat_edit => ["编辑物料", 8388608],
      :delete => ["删除物料", 16777216],
      :add_supplier => ["添加供应商",33554432],
      :supplier => ["查看供应商",67108864],
      :edit_supplier => ["编辑供应商",134217728],
      :material_loss_add => ["添加库存报损",268435456],
      :material_loss_delete => ["删除库存报损",536870912],
      :material_loss_modify => ["修改库存报损",1073741824],
    },
    :staffs => {
      :name => "员工",
      :add_staff => ["新建员工",1],
      :edit_sys_score => ["编辑系统打分",2],
      :detail_staff => ["查看员工详情",4],
      :add_priase => ["新建奖励",8],
      :add_violation => ["新建违规",16],
      :add_train => ["新建培训",32],
      :month_salary => ["本月工资",64],
      :export_salary => ["导出工资列表",128],
      :edit_salary => ["修改工资",256],
      :detail_salary => ["工资详情",512],
      :edit_show_staff => ["编辑查看员工信息",1024],
      :del_staff =>["删除员工", 2048],
      :manager_score => ["店长打分",4096],
      :del_salary => ["删除工资",8192],
      :deal_violation => ["处理奖励违规",16384],
      :search_staff => ["搜索员工", 32768]

    },
    :datas => {
      :name => "统计",
      :comp_types => ["投诉分类统计", 1],
      :comp_mingxi => ["投诉明细统计", 2],
      :pleased => ["满意度统计", 4],
      :orders => ["客户消费统计", 8],
      :lirun => ["毛利统计", 16],
      :mubiao => ["目标销售额", 32],
      :add_target => ["制定目标销售额", 64],
      :sale => ["活动订单统计", 128],
      :xiaos => ["销售报表", 256],
      :yingye => ["营业额汇总表", 512],
      :svcard => ["储值卡消费记录", 1024],
      :everyday => ["每日销售单据",2048],
      :duiz => ["储值卡对账单",4096],
      :kucun => ["库存订货统计", 8192],
      :jixiao => ["员工绩效统计", 16384],
      :shuip => ["员工平均水平统计", 32768],
      :print => ["打印单据", 65536]
    },
    :stations => {
      :name => "现场",
      :dispatch => ["分配技师",1],
      :video => ["查看现场视频",2]
    },
    :sales => {
      :name => "营销",
      :add_sale => ["添加活动",1],
      :edit_sale => ["修改活动",2],
      :publish => ["发布活动",4],
      :delete => ["删除活动",8],
      :add_product => ["添加产品",16],
      :edit_product => ["编辑产品",32],
      :delete_product => ["删除产品",64],
      :add_service => ["添加服务",128],
      :edit_service => ["编辑服务",256],
      :delete_service => ["删除服务",512],
      :add_p_card => ["添加套餐卡",1024],
      :edit_p_card => ["编辑套餐卡",2048],
      :del_p_card => ["删除套餐卡",4096],
      :show_sale_records => ["查看销售记录",8192],
      :svcard => ["添加优惠卡",16384],
      :edit_svcard => ["修改优惠卡",32768],
      :delete_svcard => ["删除优惠卡",65536],
      :svcard_sale_info => ["优惠卡销售情况",131072],
      :svcard_use_info => ["优惠卡使用情况明细",262144],
      :svcard_use_hz => ["优惠卡使用情况汇总",524288],
      :svcard_leave => ["余额查询",1048576],
      :make_billing => ["开具发票", 2097152]
    },
    :base_datas => {
      :name => "基础数据",
      :new_station_data => ["新建工位",1],
      :edit_station_data => ["编辑工位",2],
      :del_station_data => ["删除工位",4],
      :roles => ["权限",8],
      :role_conf => ["权限配置",16],
      :role_set => ["用户设定",32],
      :add_role => ["添加角色",64],
      :edit_role => ["编辑角色",128],
      :del_role => ["删除角色",256],
      :role_role_set => ["角色设定",512],
      :new_depot => ["新建仓库",1024],
      :edit_depot => ["编辑仓库",2048],
      :del_depot => ["删除仓库",4096]
    }
  }

  #上传图片的比例,如需更改请追加，部分已按index引用
  SALE_PICSIZE =[300,230,663,50]
  P_PICSIZE = [50,154,246,300,356]
  C_PICSIZE = [148,154,50]
  STAFF_PICSIZE = [100]
  SVCARD_PICSIZE = [148,154,50]
  #角色
  SYS_ADMIN = "100001"  #系统管理员
  BOSS = "100002" #老板
  MANAGER = "100003" #店长
  STAFF = "100004" #员工

  #活动code码生成文件路径
  CODE_PATH =  LOCAL_DIR + "code_file.txt"
  LOG_DIR = LOCAL_DIR + "logs/"

  PER_PAGE = 10

  #施工时间（分钟）
  STATION_MIN = 30
  W_MIN = 10 #休息时间
  #催货提醒
  URGE_GOODS_CONTENT = "门店订货提醒，请关注下"


  #  施工现场文件目录
  VIDEO_DIR ="work_videos"

  #发短信url
  MESSAGE_URL = "http://mt.yeion.com"
  USERNAME = "XCRJ"
  PASSWORD = "123456"
  
  SERVER_PATH = "http://bam.gankao.co"
  #  SERVER_PATH = "http://192.168.1.100:3001"
  HEAD_OFFICE_API_PATH = "http://headoffice.gankao.co/"
  #  HEAD_OFFICE_API_PATH = "http://192.168.1.100:3002/"

  HEAD_OFFICE = HEAD_OFFICE_API_PATH + "syncs/upload_file"
  HEAD_OFFICE_REQUEST_ZIP = HEAD_OFFICE_API_PATH + "syncs/is_generate_zip"
  HEAR_OFFICE_IPHOST= HEAD_OFFICE_API_PATH
  PCARD_PICS = "pcard_pics"
  SALE_PICS = "sale_pics"
  SVCARD_PICS = "svcardimg"
  #产品和活动的类别  图片名称分别为 product_pics 和service_pics
  PRODUCT = "PRODUCT"
  SERVICE = "SERVICE"
  UNNEED_UPDATE = ['sync','item','model','jv_sync']  #不更新的表
  DATE_START =  "2013-01"

  PIC_SIZE =1024  #按kb计算
  DATE_YEAR = 1990
  STORE_PICSIZE = [1000,50]
  #消费金额区间段
  CONSUME_P = {"0-1000"=>"o.price>0 and o.price <=1000","1000-5000"=>"o.price>1000 and o.price <=5000",
    "5000-10000"=>"o.price > 5000 and o.price <=10000","10000以上"=>"o.price > 10000"}
  PRE_DAY = 15
  ##    上面修改部分 在此处添加

  #工作订单
  WORK_ORDER_PATH = LOCAL_DIR + "work_order_data/"
end