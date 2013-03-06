#encoding: utf-8
class StaffsController < ApplicationController

  layout "staff"

  before_filter :get_store
  before_filter :search_work_record, :only => :show

  def index
    @staffs_names = @store.staffs.select("id, name")
    @staffs = @store.staffs.paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    @staff =  Staff.new
    @violation_reward = ViolationReward.new
    @train = Train.new
  end

  def create
    @staff = @store.staffs.new(params[:staff])
    @staff.photo = params[:staff][:photo].original_filename
    if @staff.save
      #save picture
      @staff.save_picture(params[:staff][:photo])
    end
    redirect_to store_staffs_path(@store)
  end

  def show
    @tab = params[:tab]
           
    @violations = @staff.violation_rewards.where("types = false").
                  paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)

    @rewards = @staff.violation_rewards.where("types = true").
                paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
              
    @trains = Train.includes(:train_staff_relations).
              where("train_staff_relations.staff_id = #{@staff.id}").
              paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)

    @month_scores = @staff.month_scores.paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)

    @salaries = @staff.salaries.where("status = false").paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)

    current_month = Time.now().strftime("%Y").to_s << Time.now().strftime("%m")

    @current_month_score = @staff.month_scores.where("current_month = #{current_month}").first

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
    @staff.update_attributes(params[:staff]) if @staff
    redirect_to store_staff_path(@store, @staff)
  end

  private

  def get_store
    @store = Store.find_by_id(params[:store_id])
  end

  def search_work_record
    @cal_style = params[:cal_style]
    @staff = Staff.find_by_id(params[:id])
    start_at = (params[:start_at].nil? || params[:start_at].empty?) ? "1 = 1" : "current_day >= '#{params[:start_at]}'"

    end_at = (params[:end_at].nil? || params[:end_at].empty?) ? "1 = 1" : "current_day <= '#{params[:end_at]}'"

    if @cal_style.nil? || @cal_style.empty? || @cal_style.eql?("day")
      @work_records = @staff.work_records.where(start_at).where(end_at).order("current_day desc").
                  paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    end
 
    if @cal_style.eql?("week") || @cal_style.eql?("month")
      base_sql = Staff.search_work_record_sql
      @work_records = @staff.work_records.select(base_sql).
        where(start_at).where(end_at).group("#{@cal_style}(current_day)").order("current_day desc").
        paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    end

  end
  
end
