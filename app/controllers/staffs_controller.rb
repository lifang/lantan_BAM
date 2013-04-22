#encoding: utf-8
class StaffsController < ApplicationController
  before_filter :sign?
  layout "staff"

  before_filter :get_store
  before_filter :search_work_record, :only => :show

  def index
    type_of_w_sql = "type_of_w = #{Staff::S_COMPANY[:FRONT]} or type_of_w = #{Staff::S_COMPANY[:TECHNICIAN]}"
    @staffs_names = @store.staffs.where(type_of_w_sql).select("id, name")
    @staffs = @store.staffs.where(type_of_w_sql).paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    @staff =  Staff.new
    @violation_reward = ViolationReward.new
    @train = Train.new
  end

  def create
    params[:staff][:username] = params[:staff][:name]
    params[:staff][:password] = params[:staff][:phone]
    @staff = @store.staffs.new(params[:staff])
    @staff.encrypt_password
    @staff.photo = params[:staff][:photo].original_filename unless params[:staff][:photo].nil?
    @staff.staff_role_relations.new(:role_id => Constant::STAFF)
    if @staff.save   #save staff info and picture
      @staff.operate_picture(params[:staff][:photo], "create") unless params[:staff][:photo].nil?
      flash[:notice] = "创建员工成功!"
    else
      flash[:notice] = "创建员工失败!"
    end
    redirect_to store_staffs_path(@store)
  end

  def show
     
           
    @violations = @staff.violation_rewards.where("types = false").
                  paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage) if @tab.nil? || @tab.eql?("violation_tab")

    @rewards = @staff.violation_rewards.where("types = true").
                paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage) if @tab.nil? || @tab.eql?("reward_tab")
              
    @trains = Train.includes(:train_staff_relations).
              where("train_staff_relations.staff_id = #{@staff.id}").
              paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage) if @tab.nil? || @tab.eql?("train_tab")

    @month_scores = @staff.month_scores.order("current_month desc").paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage) if @tab.nil? || @tab.eql?("month_score_tab")

    @salaries = @staff.salaries.where("status = false").paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage) if @tab.nil? || @tab.eql?("salary_tab")

    current_month = Time.now().months_ago(1).strftime("%Y%m")

    @current_month_score = @staff.month_scores.where("current_month = #{current_month}").first

    puts "3333333333333333333"
    puts @work_records.first.inspect
    puts "333333333333333333333"

    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @staff = Staff.find_by_id(params[:staff_id])
    respond_to do |format| 
      format.js
    end
  end

  def update
    @staff = Staff.find_by_id(params[:id])
    photo = params[:staff][:photo]
    params[:staff][:photo] = photo.original_filename unless photo.nil?
    @staff.update_attributes(params[:staff]) and flash[:notice] = "更新员工成功" if @staff
    #update picture
    @staff.operate_picture(photo, "update") if !photo.nil? && @staff
    redirect_to store_staff_path(@store, @staff)
  end

  private

  def get_store
    @store = Store.find_by_id(params[:store_id])
  end

  def search_work_record
    @staff = Staff.find_by_id(params[:id])
    @tab = params[:tab]
    puts "***************"
    puts @tab.inspect
    puts "*************"
    if @tab.nil? || @tab.eql?("work_record_tab")
      @cal_style = params[:cal_style]
      puts "&&&&&&&&&&&&&&&"
      puts @cal_style.inspect
      puts "&&&&&&&&&&&&&&&&"

      start_at = (params[:start_at].nil? || params[:start_at].empty?) ? "1 = 1" : "current_day >= '#{params[:start_at]}'"

      end_at = (params[:end_at].nil? || params[:end_at].empty?) ? "1 = 1" : "current_day <= '#{params[:end_at]} 23:59:59'"

      if @cal_style.nil? || @cal_style.empty? || @cal_style.eql?("day")
        @work_records = @staff.work_records.where(start_at).where(end_at).order("current_day desc").
                    paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
        puts "!!!!!!!!!!!!!!!!!!!!!!!!!!"
        puts @work_records.first.inspect
        puts "!!!!!!!!!!!!!!!!!!!!!!"
      end

      if @cal_style.eql?("week") || @cal_style.eql?("month")
        puts "1111111111"
        base_sql = Staff.search_work_record_sql
        @work_records = @staff.work_records.select(base_sql).
          where(start_at).where(end_at).group("#{@cal_style}(current_day)").order("current_day desc").
          paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
      end
      puts "222222222222222"
      puts @work_records.first.inspect
      puts "22222222222222222222"
    end

  end
  
end
