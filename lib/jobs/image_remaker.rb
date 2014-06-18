# encoding: utf-8
require 'resque'
 
MiniMagick.processor = :gm

#
# 注：推荐原创 灵感 文章 380* 280尺寸
#
module Jobs
  ##
  # 处理图片任务
  # 生成大图、中图、小图的过程
  #
  class ImageRemaker
    @queue = :image_remaker
    def self.perform(options={})

      id = options["id"]
      return false unless id
      #获取asset
      asset = Asset.find(id)
      return false unless asset
      begin
        origin =  asset.asset_thumb_origin
        if origin.present?
          #读取原图
          origin_path = asset.asset_type_path("sf") + origin.file_path
          image = MiniMagick::Image.open(origin_path)

          #如果是gif图需要预先处理一下
          if image.mime_type=="image/gif"
            image.combine_options(:convert) do |img|
              img.coalesce
            end
          end
          image_info = {}
          #获取Exif信息
          exif_hash = {}

          #合并Exif到exif字段
          image_info.merge!({"exif"=>exif_hash})
          #asset类型
          asset_type = Asset::ASSET_TYPE.rassoc(asset.asset_type).first.to_s

          #生成推荐尺寸
          if %w(art stuff).include?(asset_type)
            resize_bloom = [380,280]
            asset.asset_resize_thumb(image,resize_bloom, 20)
          end
          #生成封面图尺寸 和推荐的尺寸
          if  asset_type == 'media'
            # 生产ipad尺寸缩略图
            resize_pad = '460'
            asset.asset_resize_thumb(image,resize_pad, 6)
            #推荐尺寸
            resize_bloom = [380,280]
            asset.asset_resize_thumb(image,resize_bloom, 20)
            # 生产手机尺寸缩略图
            resize_p = '290'
            asset.asset_resize_thumb(image,resize_p, 5)
            # 生产小尺寸缩略图(先缩后裁形成方形图)
            resize_l = [92,92]
            asset.asset_resize_thumb(image,resize_l, 9)
          end
          # 更新附件图片信息
          asset.update_attributes(image_info)
        end
      rescue => e
        logger.warn("Make thumb and failed: #{e.message}.")
		log = Logger.new(File.join(PADRINO_ROOT, Settings.resque_error_path))
		log.debug "#{Time.now}--*ImageRemaker error: #{e.message}"
      end
    end
  end # ImageMaker


  class DelImageRemaker

    @queue = :del_image_remaker
    def self.perform(options={})
      id = options["id"]
      return false unless id
      #获取asset
      asset = Asset.find(id)
      return false unless asset
      begin
        thumb_obj =  asset.asset_thumb_crop
        if thumb_obj.present?
          #asset类型
          asset_type = Asset::ASSET_TYPE.rassoc(asset.asset_type).first.to_s

          #生成推荐尺寸
          if %w(art stuff).include?(asset_type)
            image_path = asset.asset_type_path('tf')
            f = image_path + thumb_obj.file_path
            File.delete(f)  if File.exist?(f)
            thumb_obj.destroy
          end
          #生成封面图尺寸 和推荐的尺寸
          if  asset_type == 'media'
            # 生产ipad尺寸缩略图
            resize_pad = '460'
            asset.asset_resize_thumb(image,resize_pad, 6)
            #推荐尺寸
            resize_bloom = [380,280]
            asset.asset_resize_thumb(image,resize_bloom, 20)
            # 生产手机尺寸缩略图
            resize_p = '290'
            asset.asset_resize_thumb(image,resize_p, 5)
            # 生产小尺寸缩略图(先缩后裁形成方形图)
            resize_l = [92,92]
            asset.asset_resize_thumb(image,resize_l, 9)
          end

        end
      rescue => e
        logger.warn("Make thumb and failed: #{e.message}.")
		log = Logger.new(File.join(PADRINO_ROOT, Settings.resque_error_path))
		log.debug "#{Time.now}--*DelImageRemaker error: #{e.message}"
      end
    end
  end

end # Jobs
