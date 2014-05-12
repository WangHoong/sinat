require 'mongoid'
require 'sinatra'
require "sinatra/config_file"

class Asset  
  include Mongoid::Document
 
   ##表名
  store_in collection: 'asset'

  has_many :asset_files , :class_name=>"AssetFile",:foreign_key => "asset_id" ,dependent: :destroy
 #附件类型
  ASSET_TYPE = {
	#stuff
	:stuff => 1,
	#用户头像,目前头像不存在asset中
	:avatar => 4,
	#产品首页图,可以是多个,可设置显示其中一个,暂不用
	:item_home => 5,
	#产品展示图,可以是多个
	:item_show => 6,
	#产品描述图
	:item_desc => 7,
	#征集banner图
	:theme_banner => 8,
	#征集展示图
	:theme_show =>  9,
	#作品
	:art => 10,
	#广告图片
	:advertisement => 11,
	#微博图片
	:weibo => 12,
	#编辑器的图片(征集、区块图片、小组话题上传的图片、话题回复图片,小组公告上传的图片……)
	:topic => 13,
	#media
	:media => 15,
	#活动图片
	:active => 16,
	#招聘图片
	:recruitment=>17,
	#个人中心头图
	:top_banner=>18,
	#商品属性值图片
	:propvalue=>19,
	#品牌设计师头像
	:brand_avatar=>20,
	#static_img
	:info_page=>21,
	#勋章
	:medal => 22,
	#展览封面
	:exhibition_banner => 25,
	#展览缩略图
	:exhibition_list => 26,
	#邮件图片
	:edmail => 30,
	#用户小组照片(1.头像)
	:user_group=>40,
	#频道banner
	:grandmaster_banner=>50,
	#专辑组banner图/商品／专辑封面图
	:photo_group_cover=>60,
	#词条
	:dict=>70,
	#时间戳文件
	:timestamp=>80,
	#附件
	:attachment=>90,
	#原创素材附件
	:material=>100,
	#众包背景图
	:creative_back=>91,
	#众包附件
	:creative_file=>92,
	#众包置顶图
	:creative_stick=>93
  }
  
  #处理状态
  STATE={
	  #处理失败
  	  :fail => 0,
	  #等待
	  :pending => 1,
	  #成功
	  :ok => 2
  }
  #水印
  WATER_MARK = {
    :no => 0,
    :ok => 1
  }

  ##属性
  field :stuff_id,          :type=>String
  field :original_url,      :type=>String
  field :original_file,     :type=>String
  field :filename,          :type=>String
  #处理状态
  field :state,             :type=>Integer,:default=>STATE[:pending]
  field :size,              :type=>Integer,:default=>0
  field :width,             :type=>Integer,:default=>0
  field :height,            :type=>Integer,:default=>0
  #存储fs的id,字符串类型,比如4e1e7bfccc148b0b12a00000
  field :thumb_small,       :type=>String #缩略图gridfs fileid
  field :thumb_middle,      :type=>String
  field :thumb_big,         :type=>String
  field :thumb_phone,       :type=>String
  field :thumb_bloom,  		:type=>String #展览作品缩略图thumb_bloom
  #征集附件pdf
  field :theme_pdf,       	:type=>String
  #附件类型
  field :asset_type,        :type=>Integer,:default=>ASSET_TYPE[:stuff]

  field :thumb_middle_height
  field :thumb_middle_width
  field :thumb_small_height
  field :thumb_small_width
  field :thumb_phone_height
  field :thumb_phone_width
  field :thumb_bloom_height
  field :thumb_bloom_width
  #用于存储类型,默认是jpg
  field :img_type,		:type=>String  ,:default=>"jpg"
  #图片描述信息
  field :description,   :type=>String,  :default=>nil
  #存储Exif信息
  field :exif,			:type=>Hash
  #评论数量
  field :comment_cnt,	:type=>Integer, :default=>0
  #是否有水印
  field :water_mark,	:type=>Integer,:default=>WATER_MARK[:no]
  #排序
  field :order,			:type=>Integer,:default=>0

  #原创素材的附件
  field :attach,        :type=>String
  #原创素材的附件类型
  field :attach_type,   :type=>String
  #原创素材的附件大小
  field :attach_size,   :type=>Float
  #
  field :phone_path,    :type=>String

  field :mime_type,    :type=> String
  #是否有附件
  field :is_attach,  :type=>Integer 
  field :created_on, :type => Integer
  field :updated_on, :type => Integer, :versioned => false


  set_callback :save, :before, :set_updated_at
  set_callback :create, :before, :set_created_at
    
  scope :recent,  desc(:created_on)
  
  def set_created_at
        self.created_on = Time.now.to_i if !created_on
  end
   
  def set_updated_at
     self.updated_on = Time.now.to_i
  end
 
  #原图
  def asset_thumb_origin
    obj = self.asset_files.origin.first
    return  obj if obj
    return false
  end
  #附件的图片
  def attach_origin
    obj = self.asset_files.attach.first
    return  obj if obj
    return false
  end

  #380
  def asset_thumb_middle
    obj = self.asset_files.thumb_middle.first
    return  obj if obj
    return false
  end
  #中图宽
  def thumb_middle_width
    asset_middle = self.asset_thumb_middle
    return asset_middle.width if self.asset_thumb_middle.present?
	return 0
  end
  #中图高
  def thumb_middle_height
    asset_middle = self.asset_thumb_middle
    return asset_middle.height if self.asset_thumb_middle.present?
	return 0
  end
  #宽
  def thumb_big_width
    asset_big = self.asset_thumb_big
    return asset_big.width if self.asset_thumb_big.present?
  end
  #高
  def thumb_big_height
    asset_big = self.asset_thumb_big
    return asset_big.height if self.asset_thumb_big.present?
  end

  #740
  def asset_thumb_big
    obj = self.asset_files.thumb_big.first
    return  obj if obj
    return false
  end
  #旧尺寸780 
  def asset_thumb_obig
    obj = self.asset_files.thumb_obig.first
    return  obj if obj
    return false
  end
  #180
  def asset_thumb_small
    obj = self.asset_files.thumb_small.first
    return  obj if obj
    return false
  end
  #92*92
  def asset_thumb_little
    obj = self.asset_files.thumb_little.first
    return  obj if obj
    return false
  end
  #旧尺寸 art stuff 85*85
  def asset_thumb_osmall
    obj = self.asset_files.thumb_osmall.first
    return  obj if obj
    return false
  end
  #580
  def asset_theme_middel
    obj = self.asset_files.thumb_theme_middle.first
    return  obj if obj
    return false
  end
  #1180
  def asset_theme_big
    obj = self.asset_files.thumb_theme_big.first
    return  obj if obj
    return false
  end

  #290
  def asset_thumb_phone
    obj = self.asset_files.thumb_phone.first
    return  obj if obj
    return false
  end

  #ipad
  def asset_thumb_ipad
    obj = self.asset_files.thumb_ipad.first
    return  obj if obj
    return false
  end
  #125*100
  def asset_crop_small
    obj = self.asset_files.thumb_crop_small.first
    return  obj if obj
    return false
  end
  #380*200
  def asset_thumb_bloom
    obj = self.asset_files.thumb_bloom.first
    return  obj if obj
    return false
  end
  #380*280
  def asset_thumb_crop
    obj = self.asset_files.thumb_crop.first
    return  obj if obj
    return false
  end
  #120*60
  def asset_bloom_small
    obj = self.asset_files.thumb_bloom_small.first
    return  obj if obj
    return false
  end

  #自动裁剪180*180
  def asset_crop_middle
    obj = self.asset_files.thumb_crop_middle.first
    return  obj if obj
    return false
  end

  #180*180
  def avatar_thumb_big
    obj = self.asset_files.avatar_big.first
    return  obj if obj
    return false
  end
  #100*100
  def avatar_thumb_middle
    obj = self.asset_files.avatar_middle.first
    return  obj if obj
    return false
  end
  #50*50
  def avatar_thumb_small
    obj = self.asset_files.avatar_small.first
    return  obj if obj
    return false
  end
  #30*30
  def avatar_thumb_little
    obj = self.asset_files.avatar_little.first
    return  obj if obj
    return false
  end
  #180*45
  def asset_s_banner
    obj = self.asset_files.thumb_s_banner.first
    return  obj if obj
    return false
  end


   #保存图片的url
  def asset_type_url
    case self.asset_type    
    when ASSET_TYPE[:stuff] , ASSET_TYPE[:media]
       image_url =  Setting.settings.cvidea_url
       #image_url =  Setting.settings.stuff_origin_url
    when   ASSET_TYPE[:avatar] ,  ASSET_TYPE[:top_banner] ,  ASSET_TYPE[:brand_avatar]
      image_url =  Setting.settings.cvavatar_url
    when  ASSET_TYPE[:item_home] , ASSET_TYPE[:item_show] , ASSET_TYPE[:item_desc]
      image_url =  Setting.settings.cvitem_url
    when  ASSET_TYPE[:theme_banner] , ASSET_TYPE[:theme_show] , ASSET_TYPE[:creative_back] , ASSET_TYPE[:creative_file]  ,ASSET_TYPE[:creative_stick]
      image_url =   Setting.settings.cvtheme_url
    when  ASSET_TYPE[:art]
      image_url = Setting.settings.cvart_url
      #image_url =  Setting.settings.art_origin_url
    when  ASSET_TYPE[:advertisement]
      image_url = Setting.settings.cvadvertisement_url
    when  ASSET_TYPE[:weibo] , ASSET_TYPE[:recruitment] , ASSET_TYPE[:info_page] , ASSET_TYPE[:edmail]
      image_url = Setting.settings.cvpicture_url
    when  ASSET_TYPE[:topic]
      image_url = Setting.settings.cvtopic_url
    when  ASSET_TYPE[:active]
      image_url = Setting.settings.cvactive_url
    when  ASSET_TYPE[:propvalue]
      image_url = Setting.settings.cvpropvalue_url
    when  ASSET_TYPE[:medal]
      image_url = Setting.settings.cvmedal_url
    when  ASSET_TYPE[:exhibition_banner] , ASSET_TYPE[:exhibition_list]
      image_url = Setting.settings.cvbloom_url
    when  ASSET_TYPE[:user_group]
      image_url = Setting.settings.cvgroup_url
    when  ASSET_TYPE[:grandmaster_banner]
      image_url = Setting.settings.cvchannel_url
    when  ASSET_TYPE[:photo_group_cover]
      image_url = Setting.settings.cvalbum_url
    when  ASSET_TYPE[:dict]
      image_url = Setting.settings.cvdict_url
    when  ASSET_TYPE[:timestamp]
      image_url = Setting.settings.cvtimestamp_url
    when   ASSET_TYPE[:attachment] ,  ASSET_TYPE[:material]
      image_url = Setting.settings.cvattachment_url
    else
      image_url = Setting.settings.cvpicture_url
    end
 
    return image_url
  end

  #保存图片的路径
  def asset_type_path(file_sort)
    
    case self.asset_type  
    when ASSET_TYPE[:stuff], ASSET_TYPE[:media]
      if file_sort == 'sf'      
        image_path =  Setting.settings.cvidea_srcfile
      else
        image_path = Setting.settings.cvidea_thumb
      end
    when   ASSET_TYPE[:avatar] ,  ASSET_TYPE[:top_banner] ,  ASSET_TYPE[:brand_avatar]
      image_path =  Setting.settings.cvavatar_path
    when  ASSET_TYPE[:item_home] , ASSET_TYPE[:item_show] , ASSET_TYPE[:item_desc]
      image_path =  Setting.settings.cvitem_path
    when  ASSET_TYPE[:theme_banner] , ASSET_TYPE[:theme_show] , ASSET_TYPE[:creative_back] , ASSET_TYPE[:creative_file]  ,ASSET_TYPE[:creative_stick]
      image_path =   Setting.settings.cvtheme_path
    when  ASSET_TYPE[:art]
      if file_sort == 'sf'
        image_path = Setting.settings.cvart_srcfile
      else
        image_path = Setting.settings.cvart_thumb
      end
    when  ASSET_TYPE[:advertisement]
      image_path = Setting.settings.cvadvertisement_path
    when  ASSET_TYPE[:weibo] , ASSET_TYPE[:recruitment] , ASSET_TYPE[:info_page] , ASSET_TYPE[:edmail]
      image_path = Setting.settings.cvpicture_path
    when  ASSET_TYPE[:topic]
      image_path = Setting.settings.cvtopic_path
    when  ASSET_TYPE[:active]
      image_path = Setting.settings.cvactive_path
    when  ASSET_TYPE[:propvalue]
      image_path = Setting.settings.cvpropvalue_path
    when  ASSET_TYPE[:medal]
      image_path = Setting.settings.cvmedal_path
    when  ASSET_TYPE[:exhibition_banner] , ASSET_TYPE[:exhibition_list]
      image_path = Setting.settings.cvbloom_path
    when  ASSET_TYPE[:user_group]
      image_path = Setting.settings.cvgroup_path
    when  ASSET_TYPE[:grandmaster_banner]
      image_path = Setting.settings.cvchannel_path
    when  ASSET_TYPE[:photo_group_cover]
      image_path = Setting.settings.cvalbum_path
    when  ASSET_TYPE[:dict]
      image_path = Setting.settings.cvdict_path
    when  ASSET_TYPE[:timestamp]
      image_path = Setting.settings.cvtimestamp_path
    when   ASSET_TYPE[:attachment] ,  ASSET_TYPE[:material]
      image_path = Setting.settings.cvattachment_path
    else
      image_path = Setting.settings.cvpicture_path
    end
    return image_path
  end
  
  #上传原图
  def upload_asset_original_file(image)
    begin
      file_sort = 'sf'
      new_name_file = "#{file_sort}/" + self.generate_time(Time.now)
      #文件路径
      image_root = self.asset_type_path(file_sort)
      path = image_root + "#{new_name_file}"
      #目录是否存在
      unless File.exists?(path) or File.symlink?(path)
        FileUtils.mkdir_p(path)
      end
      bson_id =  Moped::BSON::ObjectId.new
      #文件名称
      new_file_name_with_type = "#{bson_id}." + self.img_type
      file_path = "#{new_name_file}/" + new_file_name_with_type
     
      #文件路径
      file_name = image_root + file_path   
      #=========file_name end====
      #保存附件
      set_format = Setting.settings.attachment_format
      if  set_format.include?(self.img_type)
        File.write(file_name,image)
        asset_file = AssetFile.new(:type=>AssetFile::TYPE[:attachment], :asset_id=>self.id, :stuff_id=>self.stuff_id,:size=>self.size,:width=>0,:height=>0,:file_path=>file_path)
        asset_file.save
      else
        #保存原图片
        image.write file_name        
        #保存记录
        asset_file = AssetFile.new(:asset_id=>self.id,:stuff_id=>self.stuff_id,:size=>image[:size],:width=>image[:width],:height=>image[:height],:file_path=>file_path)
        asset_file.save
        logger.debug("save asset image ok.")
      end
      #赋予读权限
      FileUtils.chmod(0664, file_name)
      return asset_file.id
    rescue => e
      puts "** [Error] open file error: #{e}"
    end #end begin
  end

  def generate_time(datetime)
    date = Time.at(datetime.to_i).strftime("%y%m%d")
    return "#{date}/#{datetime.to_i/600}"
  end

 
end


 
