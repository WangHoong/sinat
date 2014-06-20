# encoding: utf-8
require 'resque'
 

MiniMagick.processor = :gm

# redstore application all jobs.
# 注：修改此文件后需要重启所有resque任务
# 3.4 bugs: 1、gm identify: Unrecognized option (-quiet)
#       2、can't convert Fixnum into String
#
module Jobs
  ##
  # 处理图片任务
  # 生成大图、中图、小图的过程
  #
  class UploadAdImage
    @queue = :upload_ad_image
    def self.perform(options={})
      id = options["id"]
      return false unless id
      #stuff ID
      obj_id = options["asset_id"]
      return false unless obj_id
      stuff_asset = Asset.find(obj_id)
      return false unless stuff_asset
      position = options["position"]

      begin         
        origin =  stuff_asset.asset_thumb_origin
        if origin.present? 
           #成功发布后，清空对应的缓存
          key = 'block:'+position
          Lgk.cache.delete(key)
        
          origin_path =  stuff_asset.asset_type_path("sf") + origin.file_path
          #生成推荐尺寸
          if %w(home_art_slide home_idea_slide home_idea_slide_second home_art_slide_second).include?(position)
            resize_bloom = [380,280]
            asset_resize_ad_thumb(id,origin_path,resize_bloom,20)
          else
            resize_b = '780'
            asset_resize_ad_thumb(id,origin_path,resize_b,1)
          end
          resize_s = [125,100]
          asset_resize_ad_thumb(id,origin_path,resize_s,7)
     
        
 
        end
      rescue => e
          puts e.message
	 log = Logger.new(File.join('log/resque_error.log'))
	 log.debug "#{Time.now}--*UploadAdImage make thumb error: #{e.message}"
      end
    end

    #上传缩略图
    def  self.asset_resize_ad_thumb(id,origin_path,resize,type)
      #获取asset
      asset = Asset.find(id)
      return false unless asset
      begin
        if origin_path.present?
          #读取原图
          image = MiniMagick::Image.open(origin_path)
          file_sort = 'tf'
          #===文件路径的处理 start =====#
          file_type = asset.img_type
          new_name_file = "#{file_sort}/" + asset.generate_time(asset.created_on)
          #文件路径
          image_root = asset.asset_type_path(file_sort)
          path = image_root + "#{new_name_file}"
          #目录是否存在
          unless File.exists?(path) or File.symlink?(path)
            FileUtils.mkdir_p(path)
          end

          bson_id =  BSON::ObjectId.new
          #文件名称
          new_file_name_with_type = "#{bson_id}." + file_type
          file_path = "#{new_name_file}/" + new_file_name_with_type
          #文件路径
          file_name = image_root + file_path
          #=========file_name end====

          #如果是gif图需要预先处理一下
          if image.mime_type=="image/gif"
            image.combine_options(:convert) do |img|
              img.coalesce
            end
          end

          if resize.class == Array
            if image[:width]<=image[:height]
              image.combine_options do |img|
                #img.resize "#{resize_s[0]}x#{resize_s[1]}!"
                #img.quality 100
                img.resize "#{resize[0]}x"
                img.quality "100"
                img.gravity "center"
                img.crop  "#{resize[0]}x#{resize[1]}+0+0"
              end
            else
              image.combine_options do |img|
                #img.resize "#{resize_s[0]}x#{resize_s[1]}!"
                #img.quality 100
                img.resize "x#{resize[1]}"
                img.quality "100"
                img.gravity "center"
                img.crop  "#{resize[0]}x#{resize[1]}+0+0"
              end
            end
          else
            image.combine_options do |img|
              if resize.include?('x')
                img.resize  "#{resize}"
              else
                img.resize  "#{resize}x>"
              end
              img.quality '100'
            end
          end
          image.write file_name
          #赋予读权限
          FileUtils.chmod(0664, file_name)
          #保存记录
          asset_file = AssetFile.new(:asset_id=>asset.id,:stuff_id=>asset.stuff_id,:size=>image[:size],:width=>image[:width],:height=>image[:height],:file_path=>file_path,:type=>type)
          asset_file.save
        end
      rescue => e
        puts "** [Error] open file error: #{e}"
        log = Logger.new(File.join('log/resque_error.log'))
	log.debug "#{Time.now}--*ImageWater open file error: #{e.message}"
      end #end begin
    end

  end #  



end # Jobs
