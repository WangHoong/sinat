# encoding: utf-8
require 'resque'
 
MiniMagick.processor = :gm

#
# 注：重新创建缩略图并删除旧的缩略图； 如果没有原图的从数据库中导出原图
#
module Jobs
  ##
  # 处理图片任务
  # 生成大图、中图、小图的过程
  #
  class ImageRebuild
    @queue = :image_rebuild
    def self.perform(options={})
      id = options["id"]
      return false unless id
      #获取asset
      asset = Asset.find(id)
      return false unless asset
      begin
        #删除旧图片
        if asset.asset_files.present? 
          asset.asset_files.no_origin.each do |f|
            path = f.file_path
            image_path = asset.asset_type_path('tf')
            file_path = image_path + path
            File.delete(file_path)  if File.exist?(file_path)
            f.destroy
          end
        end
        #生成图片
        if asset.asset_thumb_origin.present?
          asset_path = asset.asset_type_path('sf')
          orgin_file = asset.asset_thumb_origin.file_path
          orgin_path = asset_path + orgin_file
        end

        if asset.asset_files.origin.present? && orgin_path &&  File.exist?(orgin_path)
          user_name = options["user_name"]
          theme_id = options["theme_id"]
          #上传新的图片
          if user_name.present?
            if theme_id.present?
              Resque.enqueue(Jobs::ImageUpload,{:id=>asset.id,:user_name=>user_name,:theme_name=>true})
            else
              Resque.enqueue(Jobs::ImageUpload,{:id=>asset.id,:user_name=>user_name})
            end
          else
            Resque.enqueue(Jobs::ImageUpload,{:id=>asset.id})
          end

        else
          #重新在数据库中导入原图
          Resque.enqueue(Jobs::SourceAsset,{:id=>asset.id,:fs_id=>asset.original_file,:file_sort=>'sf',:type=>0})
        end

      rescue => e
        logger.warn("Make thumb and failed: #{e.message}.")
		log = Logger.new(File.join(PADRINO_ROOT, Settings.resque_error_path))
		log.debug "#{Time.now}--*ImageRebuild error: #{e.message}"
      end
    end
  end # ImageMaker

  
end # Jobs
