#! /usr/bin/env ruby

require 'snmp'
include SNMP

hostname    = ARGV[0]
community   = ARGV[1]
retcode_oid = ARGV[2]
descrip_oid = ARGV[3]

company_oid="15536"

def help
  puts "Usage:"
  puts "./check_global_logic.rb <hostname> <community> <return_code_oid> <description_oid>"
  puts ""
  puts "Example:"
  puts "./check_global_logic.rb localhost snmp_community OID"
  exit 0
end

case ARGV[0]
  when nil, "help"; then help
  exit 1
end

extOutput_OID = ObjectId.new(retcode_oid)
extResult_OID = ObjectId.new(descrip_oid)

Manager.open(:Host => hostname, :Community => community ) do |manager|
  response = manager.get([extOutput_OID, extResult_OID])
  list = response.varbind_list
  until list.empty?
    extOutput = list.shift
    extResult = list.shift
    puts "#{extResult.value}"
    exit extOutput.value.to_i
  end
end
