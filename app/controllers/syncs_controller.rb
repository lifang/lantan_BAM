#encoding: utf-8
class SyncsController < ActionController::Base

  before_filter :sign?,:except=>["upload_image"]
  
  def upload_file
    Sync.accept_file(params[:upload])
    render :text=>"success"
  end

  def upload_image
    filename = Time.now.to_i.to_s + params[:imgFile].original_filename
    time = Time.now.strftime("%Y%m%d")
    dir = "#{File.expand_path(Rails.root)}/public/upload_images"
    Dir.mkdir(dir) unless File.directory?(dir)
    Dir.mkdir("#{dir}/#{time}") unless File.directory?("#{dir}/#{time}")
    File.open("#{dir}/#{time}/#{filename}", "wb") do |f|
      f.write(params[:imgFile].read)
    end
    respond_to do |format|
      format.json {
        data={:error=>0, :url=>"/upload_images/#{time}/#{filename}", :message=>"upload_image success"}
        render :json=>data
      }
    end
  end

end