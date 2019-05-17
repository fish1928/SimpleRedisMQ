require 'redis'
require 'json'

class SimpleRedisMQHelper

  attr_reader :ip, :port, :input_channel, :output_channel

  def initialize(name, host_ip, port, input_channel, output_channel)
    @name = name
    @instance = Redis.new(host: host_ip, port: port)
    @ip = host_ip
    @port = port
    @input_channel = input_channel
    @input_lock = "#{input_channel}_lock"
    @output_channel = output_channel

    @instance.setnx(@input_lock, 0)
  end

  # push directly without lock, message is string
  def push_output!(message)
    @instance.rpush(@output_channel, message) 
  end

  # wait until get input
  def pop_input!
    input = old_lock = new_lock = nil

    while true
      if @instance.llen(@input_channel) == 0
        puts "#{@name} check empty, sleep"
        sleep(rand(5) + 5)
        next
      end

			puts "#{@name} check exists, go on"

      if (old_lock = @instance.get(@input_lock).to_i) == 0
        new_lock = @instance.incr(@input_lock).to_i

        if new_lock != 1
          puts "#{@name} check conflict, sleep"
          sleep(rand(10) * 0.1 + 1)      # sleep 1~2
					next
        end

        puts "#{@name} get key!"
        input = @instance.rpop(@input_channel)
        @instance.set(@input_lock, 0)
        break
      end

    end

    return input
  end
end
