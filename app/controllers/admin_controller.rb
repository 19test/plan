# encoding: utf-8
require 'fastercsv'
require 'csv'
class AdminController < ApplicationController
  include Init::InitHelper
  include Init::ImageHelper
  include Init::CsvHelper

  before_filter :require_login, :except => [:login, :logout] # loginsiz asla!

  def login
    redirect_to '/admin/home' if session[:admin]

    if admin = People.find_by_first_name_and_password_and_status_and_department_id(params[:first_name], params[:password], 0, 0)
      session[:admin] = true
      session[:admindepartment] = admin.department_id
      session[:adminusername] = admin.first_name
      session[:adminpassword] = admin.password
      session[:TABLES] = {
                          "People" => 'id',
                          "Lecturer" => 'id',
                          "Classroom" => 'id',
                          "Assignment" => 'id',
                          "Classplan" => 'id',
                          "Course" => 'id',
                          "Department" => 'id',
                          "Period" => 'id',
                          "Notice" => 'id',
                          }
      session[:TABLE_INIT] = "People"
      session[:FIELDS] = {
                          '_id' => true,
                          'id' => true,
                          'status' => true,
                          'name' => true,
                          'year' => false,
                          'day' => false,
                          'begin_time' => false,
                          'photo' => false,
                          'content' => false,
                          'code' => false,
      }
      unless session[:period_id] = Period.find( :first, :conditions => { :status => true })
        flash[:error] = "Dikkat! aktif bir güz/bahar yılı yok. Bu problemin düzeltilmesi için asıl yönetici ile irtibata geçin"
      end

      return table # ilk tablo seçilsin, oyun başlasın!
    end
      if params[:first_name] or params[:password]
        flash[:error] = "Oops! İsminiz veya şifreniz hatali, belkide bunlardan sadece biri hatalıdır?"
      end
  end

  def logout
    reset_session if session[:admin]
    redirect_to '/admin/'
  end

  def require_login
    unless session[:admin]
      flash[:error] = "Lütfen hesabınıza girişi yapın!"
      redirect_to '/admin/'
    end
  end

  def help
    user = "19"
    repo_wiki = "plan.wiki"
    markdown_file = "Kullanıcı-Kılavuzu.md"
    time = Time.now
    path = "#{Rails.root}/#{repo_wiki}"

    unless File.exists?("#{path}/#{markdown_file}")
      FileUtils.rm_rf path if File.exists?(path)
      system "git clone git://github.com/#{user}/#{repo_wiki}.git"
    else
      Dir.chdir(path)
      system "git pull"
    end

    system "markdown #{path}/#{markdown_file} > #{Rails.root}/app/views/home/help.html.erb"
    system "echo '\n<p id='errorline'>Update:#{time}</p>' >> #{Rails.root}/app/views/home/help.html.erb"

    flash[:success] = "Kullanıcı klavuzu güncellendi : #{time}"
    redirect_to '/admin/home'
  end

  def table
    table = if params[:table]; params[:table] else session[:TABLE_INIT] end
    flash[:success] = "#{table} tablosu başarıyla seçildi"
    session[:TABLE] = table
    session[:SAVE] = eval table.capitalize + ".count"
    session[:KEY] = session[:TABLES][table]

    if params[:table]; return redirect_to '/admin/database' else return redirect_to '/admin/home' end
  end

  def export
    if params[:csv_key]
      if params[:csv_key] == ""
        flash[:error] = "Csv ayırt edici karakter boş bırakılamaz"
        return redirect_to '/admin/export'
      end
      columns = eval(session[:TABLE] + ".columns").collect {|c| c.name}
      request_columns = params.map { |k, v| k if columns.include?(k) }.compact
      if request_columns == []
        flash[:error] = "Sütunlardan en az bir tanesini seçmelisiniz"
        return redirect_to '/admin/export'
      end
      csv_export session[:TABLE], params[:csv_key], request_columns
    end
  end

  def new
    session[:_key] = nil
  end

  def add
    photo = params[:file] if params[:file]
    columns = table_columns
    params.select! { |k, v| columns.include?(k) }

    data = eval session[:TABLE].capitalize + ".new(params)"
    data.save
    session[:_key] = data[session[:KEY]]
    session[:SAVE] += 1

    # bir resim isteğimiz var mı ?
    if photo and response = Image.upload(session[:TABLE], session[:_key].to_s, photo, false) # üzerine yazma olmasın
      if response[0] # bu yanıt iyi mi kötü mü
        data[:photo] = response[1]
        data.save
      else
        flash[:error] = response[1]
      end
    else
      data[:photo] = "/default.png"
      data.save
    end
    flash[:success] = "#{session[:_key]} bilgisine sahip kişi #{session[:TABLE]} tablosuna başarıyla eklendi"

    redirect_to '/admin/show'# göster
  end

  def find
    session[:_key] = nil
  end

  def show # post ise oturma göm + verileri göster
    session[:_key] = params[:_key] if params[:_key] # uniq veriyi oturuma gömelim
    unless @data = eval(session[:TABLE].capitalize + ".find :first, :conditions => { session[:KEY] => session[:_key] }")
      flash[:error] = "Böyle bir kayıt bulunmamaktadır"
      redirect_to '/admin/find'
    end
  end

  def review
    @data = eval session[:TABLE].capitalize + ".all"
  end

  def edit
    session[:_key] = params[:_key] if params[:_key] # post ise uniq veriyi oturuma gömelim
    @data = eval session[:TABLE].capitalize + ".find :first, :conditions => { session[:KEY] => session[:_key] }"
  end

  def del
    session[:_key] = params[:_key] if params[:_key] # post ise uniq veriyi oturuma gömelim
    eval session[:TABLE] + ".delete(session[:_key])"

    Image.delete session[:TABLE], "#{session[:_key]}.jpg"
    session[:SAVE] -= 1
    flash[:success] = "#{session[:_key]} bilgisine sahip kişi #{session[:TABLE]} tablosundan başarıyla silindi"
    session[:_key] = nil # kişinin oturumunu öldürelim

    redirect_to '/admin/review'
  end

  def update
    photo = params[:file] if params[:file]
    columns = table_columns
    params.select! { |k, v| columns.include?(k) }

    eval session[:TABLE].capitalize + ".update(session[:_key], params)"
    data = eval session[:TABLE].capitalize + ".find :first, :conditions => { session[:KEY] => session[:_key] }"

    # bir resim isteğimiz var mı ?
    if photo and response = Image.upload(session[:TABLE], session[:_key].to_s, photo, true) # üzerine yazma olsun
      if response[0] # bu yanıt iyi mi kötü mü
        data[:photo] = response[1]
        data.save
      else
        flash[:error] = response[1]
      end
    end
    flash[:success] = "#{session[:_key]} bilgisine sahip kişi #{session[:TABLE]} tablosunda başariyla güncellendi"

    redirect_to '/admin/show'# göster
  end

  private

  def table_columns # tablo sütun isimleri
    return eval(session[:TABLE] + ".columns").collect {|c| c.name}
  end
end

