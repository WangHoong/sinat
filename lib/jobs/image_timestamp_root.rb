# encoding: utf-8
require 'resque'
 

MiniMagick.processor = :gm

module Jobs
  ##
  # 改版后：处理时间戳存根图片
  #
  #
  class ImageTimestampRoot
    @queue = :image_timestamp_root

    #Resque.enqueue(Jobs::ImageTimestampRoot,{:fs_id=>fs_file_id,:art_id=>art_id})
    #fs_id:原图在fs_id表中的id
    #art_id:原图对应的原创的id
    #注：区分开fs_id与art_id(不只用art_id一个参数),防止日后一个art对应多个asset
    #注：
    #  改版前：fs_id是原图在fs.files表中的id,参见任务ImageTimestamp
    #  改版后：fs_id是原图在asset_file表中的id
    def self.perform(options={})

      begin
        fs_id=options["fs_id"].to_s
        return false unless fs_id

        #原图在asset_file中的记录
        asset_file_original = AssetFile.find(fs_id)
        return false if asset_file_original.blank?

        #原图在asset中的记录
        asset_original = asset_file_original.asset
        return false if asset_original.blank?

        art_id=options["art_id"].to_s
        return false unless art_id
        #获取art
        art=Art.find(art_id)
        return false unless art
        
        #获取用户
        user=art.user
        return false unless user
        #获取时间戳
        timestamp=art.timestamp
        return false unless timestamp
  
        return false if user.profile.realname.blank? || user.profile.id_card.blank? || art.title.blank? || art.description.blank? || timestamp.tsa.blank?
  
        #获取基础信息
        return_file_array=MongoidGenerateFileHash.generate_file_hash(fs_id)
        if return_file_array.first
          file_hash=return_file_array.second
        else
          return false
        end
        file_name=art.title

        #生成图片
        image=MiniMagick::Image.open(File.join(PADRINO_ROOT,Settings.timestamp['pic_path'],Settings.timestamp['pic_name']))
        image.combine_options do |img|
          img.font "#{File.join(PADRINO_ROOT,Settings.timestamp['font_path'],Settings.timestamp["font_name"])}"
          img.pointsize "#{Settings.timestamp['font_size']}"
          img.fill "#{Settings.timestamp['font_color']}"
          img.draw "text 320,156 '#{Rack::Utils.escape_html(Settings.timestamp['company'])}'"
          img.draw "text 320,186 '#{Rack::Utils.escape_html(timestamp.public_info)}'"
          img.draw "text 320,216 '#{Rack::Utils.escape_html(timestamp.root_hash_no_blank)}'"
          img.draw "text 200,270 '#{Rack::Utils.escape_html(file_name)}'"
          img.draw "text 200,294 '#{Rack::Utils.escape_html(user.profile.realname)}'"
          img.draw "text 200,318 '#{Rack::Utils.escape_html(timestamp.apply_at)}'"
          img.draw "text 200,342 '#{Rack::Utils.escape_html(file_hash)}'"
          img.draw "text 200,366 '#{Rack::Utils.escape_html(truncate_new(art.description,:length=>26))}'"
        end
  
        #时间戳以原图sf的类型保存
        file_sort = "sf"
        #获得磁盘目录
        image_root = asset_original.asset_type_path(file_sort)

        #生成150*150的缩略图
        origin_path = image_root + asset_file_original.file_path
        original_image=MiniMagick::Image.open(origin_path)
        if original_image[:width]<=original_image[:height]
          original_image.combine_options do |img|
            img.resize "150x"
            img.gravity "center"
            img.crop  "150x150+0+0"
          end
        else
          original_image.combine_options do |img|
            img.resize "x150"
            img.gravity "center"
            img.crop  "150x150+0+0"
          end
        end
  
        #把缩略图放到时间戳存根图片上
        result=image.composite(original_image,image[:format]) do |img|
          img.quality "100"
          img.gravity "SouthEast"
          img.geometry "+100+109"
        end
  
        #创建时间戳图片asset
        file_name_timestamp="#{file_name}_timestamp"
        asset_hash={
          :stuff_id=>timestamp.id.to_s,
          :filename=>file_name_timestamp,
          :asset_type=>Asset::ASSET_TYPE[:timestamp],
          :img_type=>result[:format],
          :width   => result[:width],
          :height  => result[:height],
          :size    => result[:size],
          :mime_type => result.mime_type,
        }

        #删除旧时间戳图片asset
        asset_olds=Asset.where(:stuff_id=>timestamp.id.to_s,:asset_type=>Asset::ASSET_TYPE[:timestamp])
        asset_olds.destroy_all if asset_olds.present?

        asset = Asset.new(asset_hash)
        if asset.save
          #存储时间戳存根图片
          asset.upload_asset_original_file(result)
          return true
        else
          return false
        end

      rescue => e
        logger.warn("Make timestamp image failed: #{e.message}.")
	log = Logger.new(File.join(PADRINO_ROOT, 'error_resque.log'))
	log.debug "*ImageTimestampRoot error: #{e.message}"
      end
      
    end#perform

    #截取文字
    def self.truncate_new(text, options={})
      options.reverse_merge!(:length => 30, :omission => "...")
      if text
        #len = options[:length] - options[:omission].length
        len = options[:length]
        chars = text
        (chars.length > options[:length] ? chars[0...len] + options[:omission] : text).to_s
      end
    end
    
  end # ImageTimestamp
end # Jobs
