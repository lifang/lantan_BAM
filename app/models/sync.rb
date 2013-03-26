#encoding: utf-8
class Sync < ActiveRecord::Base
  require 'rubygems'
  require 'net/http'
  require "uri"
  require 'openssl'
  require 'net/http/post/multipart'
  require 'zip/zip'
  require 'zip/zipfilesystem'

  #接收文件文件并存到本地
  def send_file(store_id,img_url)
    path="#{Rails.root}/public"
    dirs=["zip_dirs","/#{Time.now.strftime("%Y-%m").to_s}","/#{Time.now.strftime("%Y-%m-%d").to_s}"]
    dirs.each_with_index {|dir,index| Dir.mkdir path+dirs[0..index].join   unless File.directory? path+dirs[0..index].join }
    path="#{Rails.root}/public/"
    filename = img_url.original_filename
    File.open(path+filename, "wb")  {|f|  f.write(img_url.read) }
    #    render :text=>"success"
  end

  #发送上传请求
  def self.accept_file(store_id,file_url,filename)
    query={:store_id=>store_id}
    url = URI.parse Constant::HEAD_OFFICE
    File.open(file_url) do |file|
      req = Net::HTTP::Post::Multipart.new url.path,query.merge!("upload" => UploadIO.new(file, "application/zip", "#{filename}"))
      http = Net::HTTP.new(url.host, url.port)
      if  http.request(req).body == "success"

      end
    end
  end

  def self.get_dir_list(path)
    #获取目录列表
    list = Dir.entries(path)
    list.delete('.')
    list.delete('..')
    return list
  end


  def input_zip(store_id)
    file_path ="#{Rails.root}/public/syncs/#{Time.now.strftime("%Y-%m").to_s}/#{Time.now.strftime("%Y-%m-%d")}"
    #    file_path = "d:/sqls/"    #测试文件地址
    paths = get_dir_list(file_path)
    filename ="#{Time.now.strftime("%Y%m%d")}_#{store_id}.zip"
    File.delete(file_path+filename) if File.exists?(file_path+filename)
    Zip::ZipFile.open(file_path+filename, Zip::ZipFile::CREATE) {
      |zf|
      paths.each {|path| zf.file.open(path, "w") { |os| os.write "#{File.open(file_path+path).read}" } }
    }
    accept_file(store_id,file_path+filename,filename)
  end

  def self.output_zip(store_id)
    file_path ="#{Rails.root}/public/syncs"
    Zip::ZipFile.open(file_path+"#{Time.now.ago(1).strftime("%Y%m%d")}_#{store_id}.zip"){
      |zipFile|
      zipFile.each do |file|
        if file.name.split(".").reverse[0] =="txt"
          contents = zipFile.read(file)
          p contents.split("\n")
          p  contents.split(" ")
        end
      end
    }
  end


  def self.out_data
    models=get_dir_list("#{Rails.root}/app/models")
    models.each do |model|
      model_name =model.split(".")[0]
      unless model_name==""
        p model_name.split("_").inject(String.new){|str,name| str + name.capitalize}
        p eval(model_name.split("_").inject(String.new){|str,name| str + name.capitalize}).where("date_format(created_at,'%Y-%m')=date_format(DATE_SUB(curdate(), INTERVAL 1 MONTH),'%Y-%m')")
      end
    end
  end
end