# encoding: utf-8
class AdminController < ApplicationController
  before_filter :require_login,  :except => [:login, :logout] # loginsiz asla!
  include ImageHelper

  def login
    redirect_to '/admin/home' if session[:admin]

    if admin = People.find(:first, :conditions => { :first_name => params[:first_name], :password => params[:password] })
      if admin.department_id == 0 and admin.status == 0
        session[:error] = nil
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
                            }
        session[:TABLE_INIT] = "People"
        session[:escape] = ["created_at", "updated_at", "cell_phone", "work_phone"]
        # session[:escape] = ["id", "department_id", "period_id", "created_at", "updated_at", "status"]

        unless session[:period_id] = Period.find( :first, :conditions => { :status => 1 })
          session[:error] = "Dikkat! aktif bir güz/bahar yılı yok. Bu problemin düzeltilmesi için asıl yönetici ile irtibata geçin"
        end

        return table # ilk tablo seçilsin, oyun başlasın!
      end
    end
      if params[:first_name] or params[:password]
        session[:error] = "Oops! İsminiz veya şifreniz hatali, belkide bunlardan sadece biri hatalıdır?"
      end
  end

  def logout
    reset_session if session[:admin]
    redirect_to '/admin/'
  end

  def require_login
    unless session[:admin]
      session[:error] = "Lütfen hesabınıza girişi yapın!"
      redirect_to '/admin/'
    end
  end

  def table
    table = if params[:table]; params[:table] else session[:TABLE_INIT] end
    session[:notice] = "#{table} tablosu başarıyla seçildi"
    session[:TABLE] = table
    session[:SAVE] = eval table.capitalize + ".count"
    session[:KEY] = session[:TABLES][table]

    redirect_to '/admin/home'
  end

  def new
    session[:error], session[:notice], session[:_key] = nil, nil, nil
  end

  def home
    session[:error] = nil
  end

  def add
    session[:error] = nil

    photo = params[:file] if params[:file]
    params.select! { |k, v| eval(session[:TABLE] + ".columns").collect {|c| c.name}.include?(k) }

    data = eval session[:TABLE].capitalize + ".new(params)"
    data.save
    session[:_key] = data[session[:KEY]]
    session[:SAVE] += 1

    # bir resim isteğimiz var mı ?
    if photo and Image.upload(session[:TABLE], session[:_key].to_s, photo, false) # üzerine yazma olmasın
      data[:photo] = "#{session[:TABLE]}/#{session[:_key]}.jpg"
      data.save
    else
      data[:photo] = "default.png"
      data.save
    end
    session[:notice] = "#{session[:_key]} bilgisine sahip kişi #{session[:TABLE]} tablosuna başarıyla eklendi"

    redirect_to '/admin/show'# göster
  end

  def find
    session[:error], session[:notice], session[:_key] = nil, nil, nil
  end

  def show # post ise oturma göm + verileri göster
    session[:_key] = params[:_key] if params[:_key] # uniq veriyi oturuma gömelim
    unless @data = eval(session[:TABLE].capitalize + ".find :first, :conditions => { session[:KEY] => session[:_key] }")
      session[:error] = "Böyle bir kayıt bulunmamaktadır"
      redirect_to '/admin/find'
    end
  end

  def review
    session[:error], session[:notice] = nil, nil
    @data = eval session[:TABLE].capitalize + ".all"
  end

  def edit
    session[:error], session[:notice] = nil, nil
    session[:_key] = params[:_key] if params[:_key] # post ise uniq veriyi oturuma gömelim
    @data = eval session[:TABLE].capitalize + ".find :first, :conditions => { session[:KEY] => session[:_key] }"
  end

  def del
    session[:error], session[:notice] = nil, nil
    session[:_key] = params[:_key] if params[:_key] # post ise uniq veriyi oturuma gömelim
    eval session[:TABLE] + ".delete(session[:_key])"

    Image.delete session[:TABLE], "#{session[:_key]}.jpg"
    session[:SAVE] -= 1
    session[:notice] = "#{session[:_key]} bilgisine sahip kişi #{session[:TABLE]} tablosundan başarıyla silindi"
    session[:_key] = nil # kişinin oturumunu öldürelim

    render '/admin/find'
  end

  def update
    session[:error], session[:notice] = nil, nil

    photo = params[:file] if params[:file]
    params.select! { |k, v| eval(session[:TABLE] + ".columns").collect {|c| c.name}.include?(k) }

    eval session[:TABLE].capitalize + ".update(session[:_key], params)"
    data = eval session[:TABLE].capitalize + ".find :first, :conditions => { session[:KEY] => session[:_key] }"

    # bir resim isteğimiz var mı ?
    if photo and upload(session[:TABLE], session[:_key].to_s, photo, true) # üzerine yazma olsun
      data[:photo] = "#{session[:TABLE]}/#{session[:_key]}.jpg"
      data.save
    end
    session[:notice] = "#{session[:_key]} bilgisine sahip kişi #{session[:TABLE]} tablosunda başariyla güncellendi"

    redirect_to '/admin/show'# göster
  end

end


