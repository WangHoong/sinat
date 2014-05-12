
class AssetFile
  include Mongoid::Document
   
  ##表名
  store_in collection: 'asset_file'

  ##常量
  #附件类型
  TYPE = {
    :origin_file=>0,
    :size_780 =>1,# old(art,idea,material,media,active)
    :size_380 =>2,#(art,idea,material,media..)
    :size_180 =>3, #(art,idea,material,media..)
    :size_85_85=>4,#old theme art stuff
    :size_290=>5,#iphone 290
    :size_460=>6, #ipad 460
    :size_125x100 => 7, #(art,idea,material,media)125*100
    :size_740 => 8 ,#new art stuff item big size
    :size_92_92=>9, #(art,idea,material)
     
    :size_180x180 =>10,#user group 180*180
    :size_100x100=>11,#user group 100*100
    :size_50x50=>12, #user group 50*50
    :size_30x30=>13, #user group 30*30
    
    :size_380x280=>20, #(active,stpic)380*280
    :size_1180 => 30, #banner theme
    :size_180x45 => 31,#top_banner
    :size_180_180 => 41 ,#item medal dict

    :size_580 => 50, #theme
    #:size_85_85 => 51 ,
    :size_70x36 => 52, #theme AD
    :size_120x60 => 60 ,#exhibition
    :size_380x200 => 61,
    :attachment => 100
  }


  belongs_to :asset
 
  ##属性
  field :stuff_id,          :type=>String
  field :asset_id,          :type=>String
  field :file_path,         :type=>String
  field :size,              :type=>Integer,:default=>0
  field :width,             :type=>Integer,:default=>0
  field :height,            :type=>Integer,:default=>0
  field :type,              :type=>Integer,:default=>0
  field :fs_id,             :type=>String
  field :created_on, :type => Integer
  field :updated_on, :type => Integer, :versioned => false

  #索引
  #形成缩略图时直接查找stuff_id字段
  index({ stuff_id: 1 }, { background: true })
  scope :no_origin, where(:type.ne=>TYPE[:origin_file])
  scope :origin ,where(:type=>TYPE[:origin_file])
  scope :thumb_obig,where(:type=>TYPE[:size_780])
  scope :thumb_big,where(:type=>TYPE[:size_740])
  scope :thumb_middle,where(:type=>TYPE[:size_380])
  scope :thumb_small,where(:type=>TYPE[:size_180])
 
  scope :thumb_little,where(:type=>TYPE[:size_92_92])
  scope :thumb_osmall,where(:type=>TYPE[:size_85_85])
  scope :thumb_phone, where(:type=> TYPE[:size_290])
  scope :thumb_ipad, where(:type=> TYPE[:size_460])
  scope :thumb_bloom, where(:type=> TYPE[:size_380x200])
  scope :thumb_crop, where(:type=> TYPE[:size_380x280])
  scope :thumb_theme_middle, where(:type=> TYPE[:size_580])
  scope :thumb_theme_big, where(:type=> TYPE[:size_1180])
  scope :avatar_big, where(:type=>TYPE[:size_180x180])
  scope :avatar_middle,where(:type=>TYPE[:size_100x100])
  scope :avatar_small,where(:type=>TYPE[:size_50x50])
  scope :avatar_little,where(:type=>TYPE[:size_30x30])
  scope :thumb_crop_small,where(:type=>TYPE[:size_125x100])
  scope :thumb_crop_middle,  where(:type=>TYPE[:size_180_180])
  scope :thumb_bloom_small, where(:type=>TYPE[:size_120x60])
  scope :thumb_s_banner, where(:type=>TYPE[:size_180x45])

  #附件类型
  scope :attach , where(:type=>TYPE[:attachment])  
  scope :recent,    		desc(:created_on)

  set_callback :save, :before, :set_updated_at
  set_callback :create, :before, :set_created_at

  def set_created_at
     self.created_on = Time.now.to_i if !created_on
  end

  def set_updated_at
   self.updated_on = Time.now.to_i
  end

 end
