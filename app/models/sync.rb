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
    file_path ="#{Rails.root}/public/#{Time.now.strftime("%Y-%m").to_s}/#{Time.now.strftime("%Y-%m-%d")}"
    #    file_path = "d:/sqls/"    #测试地址
    paths = get_dir_list(file_path)
    filename ="#{Time.now.strftime("%Y%m%d")}_#{store_id}.zip"
    File.delete(file_path+filename) if File.exists?(file_path+filename)
    Zip::ZipFile.open(file_path+filename, Zip::ZipFile::CREATE) {
      |zf|
      paths.each {|path| zf.file.open(path, "w") { |os| os.write "#{File.open(file_path+path).read}" } }
    }
    accept_file(store_id,file_path+filename,filename)
  end

  

  def self.test(store_id)
   
    file_path = "d:/sqls/"
    paths = get_dir_list(file_path)
    filename ="#{Time.now.strftime("%Y%m%d")}_#{store_id}.zip"
    #    File.new(file_path)
    File.delete(file_path+filename) if File.exists?(file_path+filename)
    Zip::ZipFile.open(file_path+filename, Zip::ZipFile::CREATE) {
      |zf|
      paths.each {|path| zf.file.open(path, "w") { |os| os.write "#{File.open(file_path+path).read}" } }
    }

    #  Zip::ZipFile.open("D:/a.zip"){
    #    |zipFile|
    #    #  zipFile.get_output_stream("the first little entry") { |f| puts f.read }
    #    #  puts  zipFile.find_entry("the first little entry").nil?
    #    str =""
    #    unzip_dir="f:/exam_app/public/"
    #    match_file = File.open("f:/exam_app/public/matching.txt","rb")
    #    match_contents=""
    #    match_contents=match_file.readlines
    #    zipFile.each do |file|
    #      if file.name.split(".").reverse[0] =="txt"
    #        puts "begin to read"
    #        contents = ""
    #        contents=zipFile.read(file)
    #        content1= (contents.split(" ")-(contents.split(" ")-match_contents.join(" ").split(" ")))
    #        n=0
    #        puts file.name
    #        match_contents.each do |match_content|
    #          puts match_content
    #          if (content1-match_content.split) !=content1
    #            n +=1
    #            puts n
    #          end
    #        end
    #        if n>=10
    #          fpath = File.join(unzip_dir+"matches/", file.name)
    #          leave_content=match_contents.join(" ").split(" ")-content1
    #          File.delete(fpath) if File.exists?(fpath)
    #          zipFile.extract(file, fpath)
    #          Zip::ZipFile.open("f:/exam_app/public/txts/all.zip")  {
    #            |zf|
    #            zf.file.open("#{file.name.split(".")[0]}_none_match.txt", "w") { |os| os.write "#{leave_content.join(" ")}" }
    #            zf.file.open("#{file.name}", "w") { |os| os.write "#{File.open(fpath).read}" }
    #            zf.file.open("#{file.name.split(".")[0]}_match_num.txt", "w") { |os| os.write "#{content1.size}" }
    #          }
    #        end
    #        puts "reade  over,and read next"
    #      else
    #        str +="#{file.name}"
    #      end
    #    end
    #
    #    puts str+""
    #    match_file.close
    #  }
    ######## Using ZipInputStream alone: #######
    ##Zip::ZipInputStream.open("D:/a.zip") {
    ##
    ##  |zis|
    ##  entry = zis.get_next_entry
    ##  puts entry
    ##  print "First line of '#{entry.name} (#{entry.size} bytes):  "
    ##  puts "'#{zis.gets.chomp}'"
    ##}
    #
    #
    ######## Using ZipFile to read the directory of a zip file: #######
    #
    File
    zf = Zip::ZipFile.open("D:/a.zip", Zip::ZipFile::CREATE)
    puts zf.size
    zf.each_with_index do  |entry, index|
      puts "entry #{index} is #{entry.name}, size = #{entry.size}, compressed size = #{entry.compressed_size}"
      #  # use zf.get_input_stream(entry) to get a ZipInputStream for the entry
      #  # entry can be the ZipEntry object or any object which has a to_s method that
      #  # returns the name of the entry.
    end
    ##Zip::ZipFile.open("D:/a.zip", Zip::ZipFile::CREATE) {
    ##   |zipfile|
    ##
    ##    zipfile.get_output_stream("the first little entry") { |f| f.puts "Hello from ZipFile"; }
    ##    puts zipfile.read("the first little entry")
    ##    zipfile.get_input_stream("the first little entry") { |f| f.puts "Hello from ZipFileddddddddddddddd"; }
    ##    zipfile.mkdir("D:\a_dir")
    ##  }
    #
    #  #  zs.open("the first little entry", "w") { |os| os.write "second file1.txt" }
    #  #  zipFile.each do |entry|
    #  #    puts entry.name+"+===================="
    #  #    puts zipFile.read(entry)
    #  #  end
    #
    #
    ######## Using ZipOutputStream to write a zip file: #######
    #
    #  Zip::ZipOutputStream.open("D:/a.zip") {
    #    |zos|
    #
    #    zos.put_next_entry("the first little entry")
    #    zos.puts "Hello hello hello hello hello hello hello hello hello"
    #    zos.put_next_entry("the second little entry")
    #    zos.puts "Hello again"
    #
    #    ##  # Use rubyzip or your zip client of choice to verify
    #    ##  # the contents of exampleout.zip
    #  }
    #
    ######## Using ZipFile to change a zip file: #######
    #
    #Zip::ZipFile.open("D:/a.zip") {
    #  |zf|
    # puts zf.size
    #  zf.add("thisFile.rb", "example.rb")
    #  zf.rename("thisFile.rb", "ILikeThisName.rb")
    #  zf.add("Again", "example.rb")
    #}
    #
    ## Lets check
    #Zip::ZipFile.open("D:/a.zip") {
    #  |zf|
    #  puts "Changed zip file contains: #{zf.entries.join(', ')}"
    #  zf.remove("Again")
    #  puts "Without 'Again': #{zf.entries.join(', ')}"
    #}
    #
    ## For other examples, look at zip.rb and ziptest.rb
    #
    ## Copyright (C) 2002 Thomas Sondergaard
    ## rubyzip is free software; you can redistribute it and/or
    ## modify it under the terms of the ruby license.

  end
end
