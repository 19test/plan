# encoding: utf-8
module User
  module LecturerHelper
    include Init::ImageHelper   # resim birimi
    def lectureradd
      photo = params[:file]
      params.select! { |k, v| Lecturer.columns.collect {|c| c.name}.include?(k) }
      if flash[:error] = control({
        params[:first_name] => "Öğretim üyesinin adı",
        params[:last_name] => "Öğretim üyesinin soyadı",
  #     params[:email] => "Öğretim üyesinin eposta adresi",
      })
        return redirect_to '/user/lecturernew'
      end

      params[:first_name] = UnicodeUtils.titlecase(params[:first_name], :tr)
      params[:last_name] = UnicodeUtils.titlecase(params[:last_name], :tr)

      # params[:department_id] = session[:department_id] # doğrusu böyle olmalı
      params[:department_id] = params[:department_id] # şimdilik diğer bölümlere ekleyecek şekilde yapıyoruz.

      lecturer = Lecturer.new params
      lecturer.save
      session[:lecturer_id] = lecturer.id

      if photo and response = Image.upload('Lecturer', "#{session[:lecturer_id]}", photo, false) # üzerine yazma olmasın
        if response[0] # bu yanıt iyi mi kötü mü
          lecturer[:photo] = response[1]
          lecturer.save
        else
          flash[:error] = response[1]
        end
      else
        lecturer[:photo] = "/default.png"
        lecturer.save
      end
      flash[:success] = "#{lecturer.full_name} isimli kişi öğretim üyesini olarak eklendi"
      redirect_to '/user/lecturershow'
    end
    def lecturershow
      session[:lecturer_id] = params[:lecturer_id] if params[:lecturer_id] # uniq veriyi oturuma gömelim
      unless @lecturer = Lecturer.find(session[:lecturer_id])
        flash[:error] = "Böyle bir kayıt bulunmamaktadır"
        redirect_to '/user/lecturerreview'
      end
    end
    def lectureredit
      session[:lecturer_id] = params[:lecturer_id] if params[:lecturer_id] # uniq veriyi oturuma gömelim
      @lecturer = Lecturer.find session[:lecturer_id]
    end
    def lecturerdel
      session[:lecturer_id] = params[:lecturer_id] if params[:lecturer_id] # uniq veriyi oturuma gömelim

      if Assignment.find_all_by_lecturer_id(session[:lecturer_id]) != []
        flash[:error] = "Bu öğretim üyesinin ders ataması vardır, bu yüzden silemezsiniz. " +
          "Eğer silmek istiyorsanız, ders atamalarını siliniz. Bu da tam çözüm vermez " +
          "ise; yönetici ile irtibata geçiniz "
      else
        flash[:success] = "#{Lecturer.find(session[:lecturer_id]).full_name} Öğretim üyesini başarıyla silindi"
        Lecturer.delete session[:lecturer_id]
        Image.delete 'Lecturer', "#{session[:lecturer_id]}.jpg"
        session[:lecturer_id] = nil # kişinin oturumunu öldürelim
      end
      redirect_to '/user/lecturerreview'
    end
    def lecturerupdate
      photo = params[:file] if params[:file]
      params.select! { |k, v| Lecturer.columns.collect {|c| c.name}.include?(k) }

      if flash[:error] = control({
        params[:first_name] => "Öğretim üyesini adı",
        params[:last_name] => "Öğretim üyesini soyadı",
        params[:email] => "Öğretim üyesini email",
      })
        return redirect_to '/user/lecturershow'
      end

      params[:first_name] = UnicodeUtils.titlecase(params[:first_name], :tr)
      params[:last_name] = UnicodeUtils.titlecase(params[:last_name], :tr)

      Lecturer.update(session[:lecturer_id], params)
      lecturer = Lecturer.find session[:lecturer_id]
      if photo and response = Image.upload('Lecturer', "#{session[:lecturer_id]}", photo, true) # üzerine yazma olsun
        if response[0] # bu yanıt iyi mi kötü mü
          lecturer[:photo] = response[1]
          lecturer.save
        else
          flash[:error] = response[1]
        end
      end
      flash[:success] = "#{Lecturer.find(session[:lecturer_id]).full_name} isimli öğretim üyesini başarıyla güncellendi"
      redirect_to '/user/lecturershow'
    end
  end
end
