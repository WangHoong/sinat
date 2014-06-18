# encoding: utf-8
require 'resque'
require "xmlrpc/client"

module Jobs
  ##
  # 处理时间戳的队列.
  # 因为时间戳要根据源文件生成hash嘛，必须在s12服务器上操作.所以原先的generate_timestamp方法要独立出来，形成任务，在s12上执行.
  #
  #
  class ImageTimestampGenerate
    @queue = :image_timestamp_generate

    def self.perform(options={})
      begin
        fs_id=options["fs_id"].to_s
        return false unless fs_id
        obj_user_id=options["obj_user_id"].to_s
        return false unless obj_user_id
        obj_art_id=options["obj_art_id"].to_s
        return false unless obj_art_id
        
        obj_user = User.find(obj_user_id.to_i)
        return false unless obj_user
        obj_art = Art.find(obj_art_id)
        return false unless obj_art
		timestamp_id = options['timestamp_id'] || ''

        return_timestamp_array = generate_timestamp(:fs_id=>fs_id,:obj_user=>obj_user,:obj_art=>obj_art,:timestamp_id=>timestamp_id)
        if return_timestamp_array.first
          timestamp_info="生成时间戳成功！"
          return true
        else
          timestamp_info=return_timestamp_array.second
          #记录到日志中
          log = Logger.new "#{Padrino.root}/log/image_timestamp_generate_error.log"
          log.debug "** fs_id #{fs_id},obj_user_id #{obj_user_id},obj_art_id #{obj_art_id},error:#{timestamp_info}."
          return false
        end
      rescue => e
        logger.warn("Timestamp Generate timestamp failed: #{e.message}.")
		log = Logger.new(File.join(PADRINO_ROOT, Settings.resque_error_path))
		log.debug "#{Time.now}--*ImageTimestampGenerate 1 error: #{e.message}"
      end
    end

    #生成时间戳
    #请求：
    #  hash包括fs_id,obj_user,title,description
    #返回：
    #  [true,"成功信息"]或者[false,"错误信息"]
    #使用：
    #  generate_timestamp(:fs_id=>'...',:obj_user=>'...',:obj_art=>'...')
    #注：
    #  改版前：fs_id是原图在fs.files表中的id
    #  改版后：fs_id是原图在asset_file表中的id
    def self.generate_timestamp(hash)
      logger.debug("generate_timestamp...")
      return [false,"系统忙，请您稍候在个人中心中重新添加时间戳,谢谢！"] if hash.blank?  || hash[:fs_id].blank? || hash[:obj_user].blank? || hash[:obj_art].blank?
      #校验用户信息
      obj_user=hash[:obj_user]
      user_id=obj_user.id
      user_name=obj_user.profile.realname
      user_id_card=obj_user.profile.id_card
      if user_id.blank? || user_name.blank? || user_id_card.blank?
        return [false,"请先补充真实姓名和身份证号,再申请时间戳！"]
      end
      #校验是否有足够的时间戳数量
      if obj_user.timestamp_cnt<1
        return [false,"您的时间戳已不足，请先购买！"]
      end
      #校验作品信息
      obj_art=hash[:obj_art]
      title=obj_art.title
      description=obj_art.description
      if title.blank? || description.blank?
        return [false,"请先补充作品标题和描述,再申请时间戳！"]
      end
      #校验作品是否已经生成时间戳
      if obj_art.is_timestamp==Art::TIMESTAMP[:ok]
        return [false,"此作品已经应用过时间戳,不能再次应用！"]
      end
      #生成文件hash码
      return_generate_file_array=MongoidGenerateFileHash.generate_file_hash(hash[:fs_id])
      if return_generate_file_array.first
        projectHash=return_generate_file_array.second
      else
        return [false,return_generate_file_array.second]
      end
      #时间戳服务器相关信息
      host=Settings.timestamp.host
      path=Settings.timestamp.path
      port=Settings.timestamp.port.to_i
      function_name=Settings.timestamp.function_name
      server=::XMLRPC::Client.new(host,path,port)
      projectPartnerNumber=Settings.timestamp.partner_number
      projectPartnerKey=Settings.timestamp.partner_key
      projectFileName=::XMLRPC::Base64.encode(title.encode("GBK"))
      projectDescribe=::XMLRPC::Base64.encode(description.encode("GBK"))
      projectObligee=::XMLRPC::Base64.encode(user_name.encode("GBK"))
      projectIDCard=user_id_card
      projectIDCardType=Settings.timestamp.id_card_type
      projectTextEncode="base64"
      #生成校验码
      tsa_array=[projectPartnerNumber,projectPartnerKey,projectHash,projectFileName,projectDescribe,projectObligee,projectIDCard,projectIDCardType,projectTextEncode]
      projectVercode=Digest::MD5.hexdigest(tsa_array.join("")).upcase

      begin

#        path = File.join(PADRINO_ROOT,'/public','timestamp_param.xml')
#        File.new(path,'w') unless File.exist?(path)
#        f = File.open(path, "w")
#        f.puts('<?xml version="1.0" encoding="UTF-8"?>')
#        f.puts("<document>")
#        f.puts("<projectPartnerNumber>#{projectPartnerNumber}</projectPartnerNumber>")
#        f.puts("<projectPartnerKey>#{projectPartnerKey}</projectPartnerKey>")
#        f.puts("<projectHash>#{projectHash}</projectHash>")
#        f.puts("<projectVercode>#{projectVercode}</projectVercode>")
#        f.puts("<projectFileName>#{projectFileName}</projectFileName>")
#        f.puts("<projectDescribe>#{projectDescribe}</projectDescribe>")
#        f.puts("<projectObligee>#{projectObligee}</projectObligee>")
#        f.puts("<projectIDCard>#{projectIDCard}</projectIDCard>")
#        f.puts("<projectIDCardType>#{projectIDCardType}</projectIDCardType>")
#        f.puts("<projectTextEncode>#{projectTextEncode}</projectTextEncode>")
#        f.puts('</document>')
#        f.close

        #请求时间戳中心服务
        #response值的示例：{"status"=>"0204000","timestamp"=>"..."}
        response = server.call(function_name,projectPartnerNumber,projectPartnerKey,projectHash,projectVercode,projectFileName,projectDescribe,projectObligee,projectIDCard,projectIDCardType,projectTextEncode)
        logger.debug("response:#{response}")
        #校验请求之后的返回码,判断是否成功
        return_validate_array=validate_response(response)
        if return_validate_array.first==false
          return_value=[false,return_validate_array.second]
          #也会执行ensure中的return
          return
        end
        #请求成功后将tsa等信息赋值到本地timestamp表中
        return_update_array=update_timestamp_tsa(hash[:fs_id],obj_user,obj_art,hash[:timestamp_id],response)
        if return_update_array.first
          return_value=[true,"时间戳生成成功！"]
        else
          return_value=[false,return_update_array.second]
        end
      rescue ::XMLRPC::FaultException => e
        logger.warn("Timestamp XMLRPC::FaultException!error info:#{e}")
		log = Logger.new(File.join(PADRINO_ROOT, Settings.resque_error_path))
		log.debug "#{Time.now}--*ImageTimestampGenerate 2 error: #{e.message}"
        return_value=[false,"系统忙，请您稍候在个人中心中重新添加时间戳！"]
      ensure
        return return_value
      end

    end

    #在用户已有的未使用时间戳记录中找一个,添加tsa信息
    #请求：
    #  obj_user,obj_art,tsa_string
    #返回：
    #  [true]或者[false,'错误信息']
    def self.update_timestamp_tsa(fs_id,obj_user,obj_art,timestamp_id,response)
      tsa_string=response["timestamp"]
      if obj_user.blank? || obj_art.blank? || tsa_string.blank?
        logger.warn("Timestamp update_timestamp_tsa fail!Beacuse params blank!")
        return [false,"系统忙，请您稍候在个人中心中重新添加时间戳!!"]
      end

      user_id=obj_user.id
      if user_id.blank? || obj_art.id.blank?
        logger.warn("Timestamp update_timestamp_tsa fail!Beacuse user_id/art_id blank!")
        return [false,"系统忙，请您稍候在个人中心中重新添加时间戳"]
      end

      #选择有效的一个时间戳
	  if timestamp_id.present?
		timestamp = Timestamp.find(timestamp_id)
	  else
        timestamps=Timestamp.where(:user_id=>user_id.to_i,:used=>Timestamp::USED[:no_used])
		if timestamps.present?
		  timestamp=timestamps.first
		else
		  timestamp = ''
		end
	  end
	  
      unless timestamp.present?
        logger.warn("Timestamp update_timestamp_tsa fail!Beacuse user's timestamps blank!")
        return [false,"您没有有效的时间戳,请进行购买!"]
      end

      if timestamp.update_attributes(used: Timestamp::USED[:used],used_at: Time.now.to_i,tsa: tsa_string,art_id: obj_art.id,apply_at: response["time"],public_info: response["publicCertInfo"],root_hash: response["rootCertHash"])
		#如果是编辑生成的时间戳需要给用户发提醒
		if timestamp.type == Timestamp::TYPE[:editor_stick]
		  Alert.create(user_id: timestamp.user_id,evt: Alert::EVT[:default],type: Alert::TYPE[:timestamp_editor],related_id: timestamp.id)
		end
        #减少时间戳数量
        obj_user.inc(:timestamp_cnt,-1) if obj_user.timestamp_cnt>=1
        #art表更新字段,同时更新'授权版权'
        #obj_art.update_attribute(:is_timestamp, Art::TIMESTAMP[:ok])
        obj_art.update_attributes(is_timestamp: Art::TIMESTAMP[:ok], license: Art::ACCESS[:ok])
        #生成时间戳存根图片
        #Resque.enqueue(Jobs::ImageTimestamp,{:fs_id=>fs_id,:art_id=>obj_art.id.to_s})
        Resque.enqueue(Jobs::ImageTimestampRoot,{:fs_id=>fs_id,:art_id=>obj_art.id.to_s})
        return [true]
      else
        logger.warn("Timestamp update_timestamp_tsa fail!Beacuse timestamp updates fail!")
		log = Logger.new(File.join(PADRINO_ROOT, Settings.resque_error_path))
		log.debug "#{Time.now}--*ImageTimestampGenerate 1 error: #{e.message}"
        return [false,"系统忙，请您稍候在个人中心中重新添加时间戳。"]
      end
    end

    #校验返回信息
    #请求：
    #  response(从时间戳服务器接收到的hash信息)
    #返回：
    #  [true]或者[false,'错误信息']
    def self.validate_response(response)
      if ["0201001","0201002","0202001","0202002","0203001","0203002","0205001","0205002"].include?(response["status"])
        logger.warn("Timestamp request error,response is:#{response.to_s}")
        log = Logger.new "#{Padrino.root}/log/image_timestamp_generate_error.log"
        log.debug "#{Time.now.to_s} Timestamp request error,response is:#{response.to_s}."
        return [false,"系统忙，请您稍候在个人中心中重新添加时间戳,"]
      end
      if response["status"]=="0204001"
        log = Logger.new "#{Padrino.root}/log/image_timestamp_generate_error.log"
        log.debug "#{Time.now.to_s} Timestamp request error,response is:#{response.to_s}."
        return [false,"此作品已经申请过时间戳,不能再次申请！"]
      end
      if response["timestamp"].blank?
        logger.warn("Timestamp response's timestamp is blank!")
        log = Logger.new "#{Padrino.root}/log/image_timestamp_generate_error.log"
        log.debug "#{Time.now.to_s} Timestamp request error,response is:#{response.to_s}."
        return [false,"系统忙，请您稍候在个人中心中重新添加时间戳！"]
      end
      return [true]
    end

  end

end
