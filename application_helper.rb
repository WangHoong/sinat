module ApplicationHelper
  
  def self.included(base) 
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods 	
  end

  module ClassMethods

  end#ClassMethods

  module InstanceMethods
     def mongo_img_tag(url, options={})
      #options.reverse_merge!(:src => url)
      "<img src='#{url}'/>"      
     end

    def asset_origin_url(asset_obj)
      if asset_obj.present? and asset_obj.asset_thumb_origin.present?       
        image_url = asset_obj.asset_type_url
        image_url + asset_obj.asset_thumb_origin.file_path
      else
        Setting.settings.domain_images+'/pic_580x580.gif'
      end
    end

    def stuff_origin_tag(asset_obj,options={})
      if asset_obj.present? and asset_obj.asset_thumb_origin.present?
        image_url = asset_obj.asset_type_url
        mongo_img_tag(image_url + asset_obj.asset_thumb_origin.file_path,options)
      else
        '<img src="'+Setting.settings.domain_images+'/pic_580x580.gif" />'
      end
    end


  end
end
