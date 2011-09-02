#!/usr/bin/ruby
# encoding: utf-8
# LOCAL bir tablo oluşturma, örnek yükleme eklentisi

EXAMPLE_FILE = 'lib/tasks/insert'
MODEL = 'rails g model' # rails generate model
MIGRATE = 'db/migrate'
CONSOLE = 'rails c' # rails console

task :init => [:table, :example]

task :table do
  tables = [
    "department " +
      "name:string",

    "lecturer " +
      "department_id:integer " +
      "first_name:string " +
      "last_name:string " +
      "email:string " +
      "cell_phone:string " +
      "work_phone:string " +
      "status:boolean " +
      "photo:string ",

    "course " +
      "department_id:integer " +
      "code:string " +
      "name:string " +
      "theoretical:integer " +
      "practice:integer " +
      "lab:string " +
      "credit:integer ",

    "period " +
      "name:string " +
      "year:integer " +
      "status:boolean ",

    "classroom " +
      "name:string " +
      "floor:string " +
      "capacity:integer " +
      "type:string ",

    "assignment " +
      "period_id:integer " +
      "lecturer_id:integer " +
      "course_id:integer ",

    "classplan " +
      "period_id:integer " +
      "classroom_id:integer " +
      "assignment_id:integer " +
      "day:string " +
      "begin_time:string ",

    "people " +
      "department_id:integer " +
      "first_name:string " +
      "last_name:string " +
      "password:string " +
      "status:integer " +
      "photo:string "
  ]
  puts "tablo çerezleri siliniyor..."
  FileUtils.rm_rf MIGRATE

  puts "tablolar oluşturuluyor..."
  tables.each { |table| system "#{MODEL} #{table}" }
  system "rake db:migrate"
end

task :example do
  puts "tablolara örnekler yükleniyor..."
  system "cat #{EXAMPLE_FILE} | #{CONSOLE}"
end