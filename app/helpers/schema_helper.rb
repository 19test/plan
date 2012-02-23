# encoding: utf-8
module SchemaHelper
  def table_schema
    day = {
      "Monday" => "Pazartesi",
      "Tuesday" => "Salı",
      "Wednesday" => "Çarşamba",
      "Thursday" => "Perşembe",
      "Friday" => "Cuma",
      # "Saturday" => "Cumartesi",
      # "Sunday" => "Pazar",
    }

    header = [["Saat/Gün"] + day.values]
    morning = []
    launch = ["12", "", "", "", "", "", "", "", "", "", ""]
    evening = []
    morning_time = ["08", "09", "10", "11", "12", "13", "14", "15", "16"]
    evening_time = ["17", "18", "19", "20", "21", "22"]
    return [day, header, launch, morning, evening, morning_time, evening_time]
  end
  def departmentplan_schema period_id, department_id, year, section
    assignments = Assignment.joins(:course).where(
      'courses.department_id' => department_id,
      'assignments.period_id' => period_id
    ).select("assignments.id")
    assignments = assignments.collect { |assignment| assignment.id }

    day, header, launch, morning, evening, morning_time, evening_time = table_schema # standart tablo şeması
    if section == "0" or section == "1"
      morning_time.each do |hour|
        if hour.to_i < 13
          column = [hour + '-15' + '/' + (hour.to_i+1).to_s + '-00']
          hour = hour + '-15'
        else
          column = [hour + '-00' + '/' + hour + '-45']
          hour = hour + '-00'
        end
        if hour.slice(0..1) == launch[0]
          launch.slice(1..-1).each {|l| column << l }
          launch = column
          morning << column
        else
          day.each do |day_en, day_tr|
            classplans = Classplan.find(:all,
                                        :conditions => {
              :period_id => period_id,
              :day => day_en,
              :begin_time => hour
            }, :select => "assignment_id")
            next unless classplans
            assignment_ids = classplans.map { |classplan| classplan.assignment_id if classplan.assignment.course.year == year }.compact.uniq

            _course_codes = []
            _course_names = []
            _classroom_names = []
            _lecturer_names = []
            assignment_ids.each do |assignment_id|
              if assignments.include?(assignment_id)
                _classplan = Classplan.find(:all,
                                            :conditions => {
                  :assignment_id => assignment_id,
                  :period_id => period_id,
                  :day => day_en,
                  :begin_time => hour
                }, :select => "assignment_id, classroom_id")
                classroom_name = ""
                _classplan.each {|cp| classroom_name += cp.classroom.name + "\n"}
                _course_codes << _classplan[0].assignment.course.code
                _course_names << _classplan[0].assignment.course.name
                _lecturer_names << _classplan[0].assignment.lecturer.full_name
                _classroom_names << classroom_name
              end
            end
            if _course_codes and _course_names and _lecturer_names and _classroom_names
              column << _course_codes.uniq.join("/") +"\n" +
                _course_names.uniq.join("/") +"\n" +
                _lecturer_names.join("/")
              column << _classroom_names.join("/")
            else
              column << ""
              column << ""
            end
          end
          morning << column
        end

      end
    end
    if section == "0" or section == "2"
      evening_time.each do |hour|
        column = [hour + '-00' + '/' + hour + '-45']
        hour = hour + '-00'
        day.each do |day_en, day_tr|

          classplans = Classplan.find(:all,
                                      :conditions => {
            :period_id => period_id,
            :day => day_en,
            :begin_time => hour
          })

          next unless classplans
          assignment_ids = classplans.map { |classplan| classplan.assignment_id if classplan.assignment.course.year == year }.compact.uniq
          _course_codes = []
          _course_names = []
          _classroom_names = []
          _lecturer_names = []
          assignment_ids.each do |assignment_id|
            if assignments.include?(assignment_id)
              _classplan = Classplan.find(:all,
                                          :conditions => {
                :assignment_id => assignment_id,
                :period_id => period_id,
                :day => day_en,
                :begin_time => hour
              }, :select => "assignment_id, classroom_id")
              classroom_name = ""
              _classplan.each {|cp| classroom_name += cp.classroom.name + "\n"}
              _course_codes << _classplan[0].assignment.course.code
              _course_names << _classplan[0].assignment.course.name
              _lecturer_names << _classplan[0].assignment.lecturer.full_name
              _classroom_names << classroom_name
            end
          end
          if _course_codes and _course_names and _lecturer_names and _classroom_names
            column << _course_codes.uniq.join("/") +"\n" +
              _course_names.uniq.join("/") +"\n" +
              _lecturer_names.join("/")
            column << _classroom_names.join("/")
          else
            column << ""
            column << ""
          end

        end
        evening << column
      end
    end
    if section == "0"
      [day, header, launch, morning, evening]
    elsif section == "1"
      [day, header, launch, morning, nil]
    elsif section == "2"
      [day, header, nil, nil, evening]
    end
  end


  def classplan_schema period_id, assignments, classroom_id

    day, header, launch, morning, evening, morning_time, evening_time = table_schema # standart tablo şeması
    morning_time.each do |hour|
      if hour.to_i < 13
        column = [hour + '-15' + '/' + (hour.to_i+1).to_s + '-00']
        hour = hour + '-15'
      else
        column = [hour + '-00' + '/' + hour + '-45']
        hour = hour + '-00'
      end
      if hour.slice(0..1) == launch[0]
        launch.slice(1..-1).each {|l| column << l }
        launch = column
        morning << column
      else
        day.each do |day_en, day_tr|
          classplan = Classplan.find(:first,
                                     :conditions => {
            :classroom_id => classroom_id,
            :period_id => period_id,
            :day => day_en,
            :begin_time => hour
          })
          if classplan and assignments.include?(classplan.assignment_id)
#           column << classplan.assignment.course.code + "\n" +
            column << classplan.assignment.course.name + "\n" +
              classplan.assignment.lecturer.full_name
            column << classplan.assignment.course.department.code
          else
            column << ""
            column << ""
          end
        end
        morning << column
      end
    end

    evening_time.each do |hour|
      column = [hour + '-00' + '/' + hour + '-45']
      hour = hour + '-00'
      day.each do |day_en, day_tr|
        classplan = Classplan.find(:first,
                                   :conditions => {
          :classroom_id => classroom_id,
          :period_id => period_id,
          :day => day_en,
          :begin_time => hour
        })
        if classplan and assignments.include?(classplan.assignment_id)
#         column << classplan.assignment.course.code + "\n" +
          column << classplan.assignment.course.name + "\n" +
            classplan.assignment.lecturer.full_name
          column << classplan.assignment.course.department.code
        else
          column << ""
          column << ""
        end
      end
      evening << column
    end
    [day, header, launch, morning, evening]
  end
  def lecturerplan_schema period_id, assignments

    day, header, launch, morning, evening, morning_time, evening_time = table_schema # standart tablo şeması
    morning_time.each do |hour|
      if hour.to_i < 13
        column = [hour + '-15' + '/' + (hour.to_i+1).to_s + '-00']
        hour = hour + '-15'
      else
        column = [hour + '-00' + '/' + hour + '-45']
        hour = hour + '-00'
      end
      if hour.slice(0..1) == launch[0]
        launch.slice(1..-1).each {|l| column << l }
        launch = column
        morning << column
      else
        day.each do |day_en, day_tr|
          classplans = Classplan.find(:all,
                                      :conditions => {
            :period_id => period_id,
            :day => day_en,
            :begin_time => hour
          }, :select => "assignment_id")
          assignment_ids = classplans.collect { |classplan| classplan.assignment_id }
          assignment_state = false
          _assignment_id = ""
          assignment_ids.each do |assignment_id|
            if assignments.include?(assignment_id)
              _assignment_id = assignment_id
              assignment_state = true
              break
            end
          end
          if assignment_state
            classplan = Classplan.find(:all,
                                       :conditions => {
              :assignment_id => _assignment_id,
              :period_id => period_id,
              :day => day_en,
              :begin_time => hour
            }, :select=>"assignment_id, classroom_id")
            classroom_name = ""
            classplan.each {|cp| classroom_name += cp.classroom.name + "\n"}
            column << classplan[0].assignment.course.code + "\n" +
              classplan[0].assignment.course.name
            column << classroom_name
          else
            column << ""
            column << ""
          end
        end
        morning << column
      end
    end

    evening_time.each do |hour|
      column = [hour + '-00' + '/' + hour + '-45']
      hour = hour + '-00'
      day.each do |day_en, day_tr|
        classplans = Classplan.find(:all,
                                   :conditions => {
          :period_id => period_id,
          :day => day_en,
          :begin_time => hour
        }, :select => "assignment_id")
        assignment_ids = classplans.collect { |classplan| classplan.assignment_id }

        assignment_state = false
        _assignment_id = ""
        assignment_ids.each do |assignment_id|
          if assignments.include?(assignment_id)
            _assignment_id = assignment_id
            assignment_state = true
            break
          end
        end

        if assignment_state
            classplan = Classplan.find(:all,
                                       :conditions => {
              :assignment_id => _assignment_id,
              :period_id => period_id,
              :day => day_en,
              :begin_time => hour
            }, :select=>"assignment_id, classroom_id")
            classroom_name = ""
            classplan.each {|cp| classroom_name += cp.classroom.name + "\n"}
            column << classplan[0].assignment.course.code + "\n" +
              classplan[0].assignment.course.name
            column << classroom_name
        else
          column << ""
          column << ""
        end
      end
      evening << column
    end
    [day, header, launch, morning, evening]
  end
end
