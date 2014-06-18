# encoding: utf-8
require 'resque'
require "open-uri"

module Jobs
  ##
  # 作品导出
  #
  class ExportThemeWork
    @queue = :export_theme_work
    def self.perform(theme_id,category_id)
		#导出作品
		export_contest_image(theme_id,category_id)
		#导出用户
		export_contest_user(theme_id,category_id)
    end
    
    def self.export_contest_image(theme_id,category_id)
	    begin
		    if theme_id.present?
			    path = Settings.domain_theme_file + "#{theme_id}/"
			    des_mkdirs(path,0777) unless File.exist?(path)
			    #错误日志
			    log = Logger.new(File.join(PADRINO_ROOT, Settings.resque_error_path))
			    if category_id.present?
				    #创建带子目录的方法
				    path = Settings.domain_theme_file + "#{theme_id}/" + "#{category_id}/"
					des_mkdirs(path,0777) unless File.exist?(path)
					arts = Art.undeleted.recent.where(:theme_id=>theme_id,:category_id=>category_id)
				else
					arts = Art.undeleted.recent.where(:theme_id=>theme_id)
				end
		    end
		    
		    if arts.present?
				arts.each do |art|
					puts "begin art:#{art.id}" if art.present?
					#单张图
					if art.assets.count == 1
						if art.asset.present? and art.asset.asset_thumb_origin.present?
							path_old = Settings.cvart_srcfile + art.asset.asset_thumb_origin.file_path
							if File.exist?(path_old)
								path_new = path + art.id.to_s + "." + art.asset.img_type
								FileUtils.cp path_old,path_new
								puts "#{art.asset.id} is ok"
							else
								puts "file no exist #{path_old}"
								log.debug "#{Time.now}--**ExportContestImage file no exist #{path_old}"
							end
						else
							puts "single #{art.id.to_s} is error,asset skip...!!!"
							log.debug "#{Time.now}--**ExportContestImage Asset {art.id.to_s}"
						end
					else
						# 系列图片
						art.assets.each do |asset|
							if asset.present? and asset.asset_thumb_origin.present?
							path_old = Settings.cvart_srcfile + asset.asset_thumb_origin.file_path
								if File.exist?(path_old)
									path_new = path + art.id.to_s + "_#{asset.order}" + "." + asset.img_type
									FileUtils.cp path_old,path_new
									puts "#{asset.id} is ok"
								else
									puts "file no exist #{path_old}"
									log.debug "#{Time.now}--**ExportContestImage file no exist #{path_old}"
								end
							else
								puts "multiple #{art.id.to_s} is error,asset skip...!!!"
								log.debug "#{Time.now}--**ExportContestImage Asset #{art.id.to_s}"
							end
						end						
					end
				end
		    end
		rescue => e
			puts "export theme art works failed: #{e.message}."
			log.debug "#{Time.now}--**ExportContestImage export theme art works failed: #{e.message}."
	    end 
    end#export_contest_image
    
    def self.export_contest_user(theme_id,category_id)
		begin
		if theme_id.present? || category_id.present?
		
		per_page = 10000
		#下一id
		next_id = Art.asc(:_id).first.id
		#记录页数
		page = 1
			while true
				if page == 1
					#查询条件theme_id
					if theme_id.present?
						#错误日志
						log = Logger.new(File.join(PADRINO_ROOT, Settings.resque_error_path))
						#如果征集中存在分类，单独导出征集中的分类
						if category_id.present?
							@arts = Art.undeleted.where(:theme_id=>theme_id,:category_id=>category_id,:_id.gte=>next_id).asc(:_id).limit(per_page)
						else
							@arts = Art.undeleted.where(:theme_id=>theme_id,:_id.gte=>next_id).asc(:_id).limit(per_page)
						end
					else
						p "export_contest_user <theme=""> [<category="">]"
						log.debug "#{Time.now}--**ExportContestUser export_contest_user <theme=""> [<category="">]"
					end
				else
					#查询条件theme_id
					if theme_id.present?
						#如果征集中存在分类，单独导出征集中的分类
						if category_id.present?
							@arts = Art.undeleted.where(:theme_id=>theme_id,:category_id=>category_id,:_id.gt=>next_id).asc(:_id).limit(per_page)
						else
							@arts = Art.undeleted.where(:theme_id=>theme_id,:_id.gt=>next_id).asc(:_id).limit(per_page)
						end
					else
						p "export_contest_user <theme=""> [<category="">]"
						log.debug "#{Time.now}--**ExportContestUser export_contest_user1 <theme=""> [<category="">]"
					end
				end
				
				if @arts.present?
				book = Spreadsheet::Workbook.new
				#表格名
				sheet1 = book.create_worksheet :name => "export_user"
				#首行
				sheet1.row(0).concat %w{ID 作品名 作品说明 昵称 邮箱 姓名 职业 手机 地址 学校 作品链接 上传时间 联合策展人ID}
					@arts.each_with_index do |art,i|
					next_id = art.id
					i += 1
					sheet1[i,0] = art.id.to_s
					sheet1[i,1] = art.title
					sheet1[i,2] = art.description
					sheet1[i,3] = art.user.nickname
					sheet1[i,4] = art.user.passport
					if art.user.profile.present?
						if art.user.profile.realname.present?
							sheet1[i,5] = art.user.profile.realname
						else
							sheet1[i,5] = "这家伙很懒 没有填写"
						end
						if art.user.profile.job.present?
							sheet1[i,6] = art.user.profile.job
						else
							sheet1[i,6] = "这家伙很懒 没有填写"
						end
						if art.user.profile.phone.present?
							sheet1[i,7] = art.user.profile.phone
						else
							sheet1[i,7] = "这家伙很懒 没有填写"
						end
						if art.user.profile.address.present?
							sheet1[i,8] = art.user.profile.address
						else
							sheet1[i,8] = "这家伙很懒 没有填写"
						end
						if art.user.profile.school.present?
							sheet1[i,9] = art.user.profile.school
						else
							sheet1[i,9] = "这家伙很懒 没有填写"
						end
					else
						puts "error user profile nil #{art.user.id}"
						log.debug "#{Time.now}--**ExportContestUser error user profile nil #{art.user.id}"
					end
					sheet1[i,10] = "http://shijue.me/zone/show_art/" + art.id.to_s			  
					sheet1[i,11] = format_time(art.created_on)
					sheet1[i,12] = art.target_user_id
					end
				#文件命名
				time = Time.new
				book.write Settings.domain_theme_file + theme_id.to_s + category_id.to_s + "_#{page}_" + time.month.to_s + time.day.to_s + ".xls"
				p "export contest theme #{theme_id} is page:#{page},art sum#{@arts.count} is ok ..."
				end
				
				page += 1
				#跳出循环
				break if @arts.count < per_page
			end #while
		else
			p "Usage: export_contest_user <theme=""> [<category="">]"
			log.debug "#{Time.now}--**user Usage: export_contest_user <theme=""> [<category="">]"
		end
		rescue => e
			# 抛出异常
			p "export contest user erroe #{e.message}"
			log.debug "#{Time.now}--**ExportContestUser export contest user erroe #{e.message}"
		end
    end#export_contest_user
    
    #多目录创建
	def self.des_mkdirs(path,level)
		if(!File.directory?(path))
			if(!des_mkdirs(File.dirname(path),level))
				return false;
			end
			Dir.mkdir(path,level)
		end
		return true
    end
    
  end #ExportThemeWork
end #Jobs
