# get_ip_be.br - Helper to get backend ip address
# Version 0.1
# Date 25/09/2012 - <francisco.cabrita@gmail.com>

require 'rubygems'
require 'socket'

@act = ARGV[0].dup unless ARGV[0].nil?
@dip = ARGV[1].dup unless ARGV[1].nil?


# Class to get local ip address used to connect to remote host
class GetIpBe
	attr_accessor :destIp

	def initialize (*destIp)
		@destIp = destIp[0]
	end


	# socket brain
	def localIp

		# turn off reverse DNS resolution temporarily
		orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true

		UDPSocket.open do |s|
			s.connect @destIp, 1
			s.addr.last
		end
	ensure
		Socket.do_not_reverse_lookup = orig
	end


	# tiny help
	def myHelp
		puts "\nUsage:"
        puts " get_ip_be.rb --help"
        puts " get_ip_be.rb --try <ip to try>"
        puts ""
        puts "Example:"
        puts " ./get_ip_be.rb --try 10.0.0.1"
        Kernel.exit 1	
	end
end

case @act
when '--try' then
    if ARGV.length < 2 then
        GetIpBe.new.myHelp
    else
        calc = GetIpBe.new @dip
        puts calc.localIp
    end
when '--help', '-h' then
    GetIpBe.new.myHelp
else
	GetIpBe.new.myHelp
end
