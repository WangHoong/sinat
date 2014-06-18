# encoding: utf-8
require 'resque'
require 'fileutils'

module Jobs
  ##
  # 导出图片从数据库至磁盘
  # 注：修改此文件后需要重启所有resque任务
  #
  class SourceAsset
    @queue = :source_asset
    
    def self.perform(options={})
      
      begin
        fs_id = options['fs_id']
        return false unless fs_id
        
        ## 获取asset
        obj_id = options['id']
        asset  = Asset.find(obj_id)
        return false unless asset

        file_sort = options['file_sort']
        type_id   = options['type']
        
        @grid = $grid
        #获取源图片文件
        fs = @grid.get(BSON::ObjectId.from_string(fs_id))
                
        if asset.img_type.present?
          file_type = asset.img_type
        elsif asset.mime_type.present?
          file_type = asset.mime_type.split('/').last || 'jpg'
        else
          file_type = 'jpg'
        end

        new_name_file = "#{file_sort}/"  + asset.generate_time(asset.created_on)
        #文件名称
        new_file_name_with_type = "#{fs_id}." + file_type

        image_root = asset.asset_type_path(file_sort)
 
        path = image_root + "#{new_name_file}"

        unless File.exists?(path) or File.symlink?(path)
          FileUtils.mkdir_p(path)
        end

        file_path = "#{new_name_file}/" + new_file_name_with_type
        #文件路径
        file_name = image_root + file_path
        puts "Write #{obj_id},#{fs_id} file #{file_name}."

        #删除已经存在的图片
        asset_file = asset.asset_files.origin.first
        if asset_file.present?
          f = image_root + asset_file.file_path
          File.delete(f)  if File.exist?(f)
          asset_file.destroy
        end
        #保存附件 
        #attachment_format: ['pdf','PDF','zip','rar','doc','ppt']
        set_format = Settings.attachment_format
        if  set_format.include?(asset.img_type)
          File.write(file_name,fs.read)
          asset_file = AssetFile.new(:asset_id=>asset.id,:fs_id=>fs_id,:stuff_id=>asset.stuff_id,:size=>asset.size,:width=>0,:height=>0,:file_path=>file_path,:type=>type_id)
          asset_file.save
        else
          image = MiniMagick::Image.read(fs)
          puts "Write #{obj_id},#{fs_id} image #{file_name}." 
          #保存原图片
          image.write file_name
          asset_file = AssetFile.new(:asset_id=>asset.id,:fs_id=>fs_id,:stuff_id=>asset.stuff_id,:size=>image[:size],:width=>image[:width],:height=>image[:height],:file_path=>file_path,:type=>type_id)
          #保存记录并且是原图
          if asset_file.save && type_id == 0
            Resque.enqueue(Jobs::ImageUpload,{:id=>asset.id})
          end
        end
        #赋予读权限
        FileUtils.chmod(0664, file_name)          
        
      rescue => e
        puts "** [Error] open file error: #{e}"
        log = Logger.new '/cvasset/asset_error02.log'
        log.debug "** Asset #{obj_id},fs_id #{fs_id} error: #{e.message}"
      end #end begin
      
    end #end def
    
  end #end class
 

end
