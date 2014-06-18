# encoding: utf-8
require 'resque'

MiniMagick.processor = :gm

# redstore application all jobs.
module Jobs
  ##
  # Fetch images into db from remote url
  #注：修改此文件后需要重启所有resque任务
  #
  class ImageFetcher
    #修改为磁盘存储图片之前
    #@queue = :image_urlist
    #修改为磁盘存储图片之后
    @queue = :image_urlist_disk
    
    def self.perform(id,options={})
      logger.debug("Start to find asset[#{id}].")
      asset = Asset.find(id)
      return false unless asset
      
      begin
        uri = URI.escape(asset.original_url)
        logger.debug("Start to fetch image[#{uri}].")
        image = Timeout::timeout(30) {
          # 抓取图片
          MiniMagick::Image.open(uri)
        }
        # 获得宽度,高度,格式,大小: 
        filename = File.basename(uri)
        image_info = {
          :width   => image[:width],
          :height  => image[:height],
          :size    => image[:size],
          :mime_type => image.mime_type,
          :filename  => filename
        }
 
        # 获取数据库链接
        
        logger.debug("Update asset image info.")
       
        asset.update_attributes(image_info)
        
        asset.upload_asset_original_file(image)
        # 添加生成缩略图任务 处理雪花水印
        if options["name"].present?
          Resque.enqueue(Jobs::ImageUpload,{:id=>asset.id,:user_name=>options["name"],:theme_name=>true})
        else
          Resque.enqueue(Jobs::ImageUpload,{:id=>asset.id})
        end
        
      rescue => e
        logger.warn("Fetch image and failed: #{e.message}")
        log = Logger.new(File.join(PADRINO_ROOT, Settings.resque_error_path))
        log.debug "#{Time.now}--*ImageFetcher error: #{e.message}"
      end
      
    end
    
  end # ImageFetcher
end # Jobs
