# encoding: utf-8
require 'resque'
#MiniMagick.processor = :gm

#  
# 注：上传缩略图的任务
#
module Jobs
  ##
  # 处理图片任务
  # 生成大图、中图、小图的过程
  #
  class ImageUpload
    @queue = :image_upload
    def self.perform(options={})
      p '==============='
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

          #====art stuff
          if %w(art stuff material).include?(asset_type)
            set_format = Settings.attachment_format
            unless  set_format.include?(asset.img_type)
              # 获取作者姓名
              user_name = options["user_name"]
              user_name = Settings.water_mark["font_no_user"] unless user_name
            
              theme_name = options['theme_name']
              # 生产大尺寸缩略图
              resize_b = '740'
              asset.asset_resize_thumb(image,resize_b,8,user_name,theme_name)
              # 生产ipad尺寸缩略图
              resize_pad = '460'
              asset.asset_resize_thumb(image,resize_pad, 6)
              # 生产中尺寸缩略图
              resize_m = '380'
              asset.asset_resize_thumb(image,resize_m, 2)
              # 生产手机尺寸缩略图
              resize_p = '290'
              asset.asset_resize_thumb(image,resize_p, 5)
              # 生产小尺寸缩略图
              resize_s = '180'
              asset.asset_resize_thumb(image,resize_s, 3)

              # thumb_crop 生产中尺寸缩略图(先缩后裁)
              resize_c = [125,100]
              asset.asset_resize_thumb(image,resize_c, 7)

              # 生产小尺寸缩略图(先缩后裁形成方形图)
              resize_l = [92,92]
              asset.asset_resize_thumb(image,resize_l, 9)       
            end
          end

          #======art stuff end===========
          if %w(media).include?(asset_type)
            # 生产大尺寸缩略图
            resize_b = '740'
            asset.asset_resize_thumb(image,resize_b, 8)
            # 生产中尺寸缩略图
            resize_m = '380'
            asset.asset_resize_thumb(image,resize_m, 2)
            # 生产小尺寸缩略图
            resize_s = '180'
            asset.asset_resize_thumb(image,resize_s, 3)
            # thumb_crop 生产中尺寸缩略图(先缩后裁)
            resize_c = [125,100]
            asset.asset_resize_thumb(image,resize_c, 7)
          end

          #banner图片
          if %w(theme_banner top_banner).include?(asset_type)
            banner_b = '1180'
            asset.asset_resize_thumb(image,banner_b, 30)
          end
 
          #banner middle and item big
          if %w(item_show item_desc item_home topic advertisement).include?(asset_type)
            banner_m = '780'
            asset.asset_resize_thumb(image,banner_m, 1)
          end

          if %w(attachment).include?(asset_type)
            banner_b = '740'
            asset.asset_resize_thumb(image,banner_b, 8)
          end

          if asset_type == 'theme_show'
            #thumb middle
            #            theme_m = '580'
            #            asset.asset_resize_thumb(image,theme_m, 50)
            theme_b = '1180'
            asset.asset_resize_thumb(image,theme_b, 30)
          end

          if %w(active item_show item_home topic item_desc edmail theme_show theme_banner).include?(asset_type)
            #thumb item middle
            thumb_item_m = '380'
            asset.asset_resize_thumb(image,thumb_item_m, 2)
          end

          #活动裁剪图
          if  %w(active exhibition_banner exhibition_list photo_group_cover advertisement).include?(asset_type)
            # 生产bloom缩略图
            resize_bloom = [380,280]
            asset.asset_resize_thumb(image,resize_bloom, 20)
          end

          #活动和专辑上传图
          if %w(active photo_group_cover attachment).include?(asset_type)
            resize_s = '180'
            asset.asset_resize_thumb(image,resize_s, 3)
          end

          if %w(item_show item_home item_desc medal dict).include?(asset_type)
            #thumb item show
            thumb_item_s = [180,180]
            asset.asset_resize_thumb(image,thumb_item_s, 41)
          end

          #top banner
          if asset_type == 'top_banner'
            banner_wh = '180x45'
            asset.asset_resize_thumb(image,banner_wh, 31)
          end

          if %w(advertisement topic theme_show).include?(asset_type)
            resize_c = [125,100]
            asset.asset_resize_thumb(image,resize_c, 7)
          end

          if %w(grandmaster_banner exhibition_banner exhibition_list creative_file).include?(asset_type)
            banner_wh = '120x60'
            asset.asset_resize_thumb(image,banner_wh,60)
          end
 
        
          if asset_type == 'attachment'
            banner_wh = '100x100'
            asset.asset_resize_thumb(image,banner_wh, 11)
          end             

          #广告栏目 #原图和thumb_big是一个图
          if  asset_type == 'theme_banner'
            banner_wh = '70x36'
            asset.asset_resize_thumb(image,banner_wh, 52)
          end

          #medal  block
          if asset_type == 'medal'
            medal_wh = '50x50'
            asset.asset_resize_thumb(image,medal_wh, 12)
          end
     
          #用户小组
          if asset_type == 'user_group'
            avatar_b = '180x180'
            asset.asset_resize_thumb(image,avatar_b,10)

            avatar_m = '100x100'
            asset.asset_resize_thumb(image,avatar_m,11)

            avatar_s = '50x50'
            asset.asset_resize_thumb(image,avatar_s,12)

            avatar_l = '30x30'
            asset.asset_resize_thumb(image,avatar_l,13)
          end
      
          # 更新附件图片信息
          asset.update_attributes(image_info)
        end
      rescue => e
        logger.warn("Make thumb and failed: #{e.message}.")
		log = Logger.new(File.join(PADRINO_ROOT, Settings.resque_error_path))
		log.debug "#{Time.now}--*ImageUpload error: #{e.message}"
      end
    end
  end # ImageMaker

  class DelAssetFile
    @queue = :del_asset_file
    def self.perform(options={})
      begin
        file_path = options["file_path"]
        return false unless file_path
        File.delete(file_path)  if File.exist?(file_path)
      rescue => e
        puts "** [Error] open file error: #{e}"
		log = Logger.new(File.join(PADRINO_ROOT, Settings.resque_error_path))
		log.debug "#{Time.now}--*DelAssetFile error: #{e.message}"
      end
    end
  end # DelAssetFile

end # Jobs

