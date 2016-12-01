#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'csv'
require 'mechanize'

### ARGV check
if ARGV.empty?
  puts "Usage: #{$0} <input-file.csv>"
  exit
end

### environment
#csv_input_file = './cfname_test.csv'
csv_input_file = ARGV[0]
csv_success_file = './group_success.csv'
csv_failure_file = './group_failure.csv'
result_success = []
result_failure = []

username = 'admin'
password = 'Inte11i8ence'

host = 'localhost'
url_root = 'http://' + host
url_login = url_root + '/login'
url_logout = url_root + '/logout'

cf_id = 240
cf_name = "group[custom_field_values][#{cf_id}]"
cf_val = 'IBS'


### CSV load
#   CSV: <UID>, <CustomValue>, <AAA>, <BBB>, ...
#   => Array:[[<UID>, <CustomValue>], ...]
#   => Hash: {<UID>: <CustomValue>, ...}
#
#   ex.)
#   CSV: 1,\n 2,IBS\n 3,THD\n 4,\n
#   => Hash: {"1"=>nil, "2"=>"IBS", "3"=>"THD", "4"=>nil}
begin
  csv_input_array = CSV.read(csv_input_file)
  csv_input_array.collect! {|ary| [ary[0], ary[1]]}
  csv_input_hash = Hash[*csv_input_array.flatten]
  puts "--------------------------------------------"
  puts "INFO: complete CSV load! #{csv_input_hash.length} records."
  puts "--------------------------------------------"
rescue => e
  STDERR.puts "ERROR:[CSV load]: #{e}"
  exit
end

### temaheras login
agent = Mechanize.new
page = agent.get(url_login)
form = page.forms[0]
form.username = username
form.password = password
page = agent.submit(form)

### groups/<id>/edit
begin
  csv_success = CSV.open(csv_success_file, 'w')
  csv_failure = CSV.open(csv_failure_file, 'w')

  csv_input_hash.each_with_index do |(uid, cf_val), i|
    begin
      p [i,  [uid, cf_val]]
      next if uid.to_i == 0
      next if cf_val.nil?
      print ' => '
      url_path = url_root + "/groups/#{uid}/edit"
      page = agent.get(url_path)
      form = page.forms[1]
      p form.field_with(:name => cf_name)
      form.field_with(:name => cf_name).value = cf_val
      page = agent.submit(form)

      ### groupsの場合は保存後にページ遷移してしまうのでeditに戻る
      page = agent.get(url_path)
      ###
      form = page.forms[1]
      print ' => '
      p form.field_with(:name => cf_name)
      result = form.field_with(:name => cf_name).value
      if result == cf_val
        csv_success.puts [uid, cf_val]
      else
        e = "ToBe=`#{cf_val}`, Result=`#{result}`"
        STDERR.puts "ERROR:[groups/edit]: #{e}"
        csv_failure.puts [uid, cf_val, e]
      end
    rescue => e
      STDERR.puts "ERROR:[groups/edit]: #{e}"
      csv_failure.puts [uid, cf_val, e]
    end
  end
rescue => e
  STDERR.puts "ERROR:[CSV result write]: #{e}"
  exit
ensure
  csv_success.close
  csv_failure.close
end

### logout
page = agent.get(url_logout)
link = page.link_with(:href => '/logout')
link.click
