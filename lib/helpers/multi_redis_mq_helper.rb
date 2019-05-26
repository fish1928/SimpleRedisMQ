require 'redis'
require 'json'

class MultiRedisMQHelper

  attr_reader :ip, :port, :input_channel, :output_channel

  def initialize(name, host_ip, port, input_channels, output_channel)
    @name = name
    @instance = Redis.new(host: host_ip, port: port)
    puts "#{@instance.keys('*')}"
    @ip = host_ip
    @port = port

    @input_channels = input_channels
    @input_locks = @input_channels.map { |input_channel| "#{input_channel}_lock" }
    @input_overall_lock = "#{@input_channels.sort.map{ |channel| channel}.join('_')}_lock"

    @output_channel = output_channel

    @input_locks.each { |input_lock| @instance.setnx(input_lock, 0) }
    @instance.setnx(@input_overall_lock, 0)
  end

  # push directly without lock, message is string
  def push_output!(message)
    @instance.rpush(@output_channel, message) 
  end

  # wait until get input
  def pop_input!
    inputs = old_overall_lock = new_overall_lock = nil

    while true
      has_all_input = true
      @input_channels.each do |input_channel|
        has_all_input &&= (@instance.llen(input_channel) != 0)
        break if !has_all_input
      end

      if !has_all_input
        puts "#{@name} check empty, sleep"
        sleep(rand(5) + 5)
        next
      end

			puts "#{@name} check exists, go on"

      # this if means maybe get the overall lock
      if(old_overall_lock = @instance.get(@input_overall_lock).to_i == 0)
        new_overall_lock = @instance.incr(@input_overall_lock).to_i

        if new_overall_lock != 1
          puts "#{@name} check conflict, sleep"
          sleep(rand(10) * 0.1 + 1)
          next
        end

        puts "#{@name} get overall key!"
      

        get_key_channels = []
        @input_locks.each do |input_lock|
          this_key = @instance.incr(input_lock).to_i
          if this_key == 1 # get this key
            get_key_channels << input_lock
          end
        end

        # not getting all locks
        if get_key_channels.size < @input_locks.size

          # give back individual locks
          get_key_channels.each do |get_key_channel|
            @instance.set(get_key_channel, 0)
          end

          # give back overall lock
          @instance.set(@input_overall_lock, 0)
          puts "#{@name} check some inputs has conflict, sleep"
          sleep(rand(10) * 0.1 + 1)
          next
        end

        puts "#{@name} get all keys, pop inputs"
        inputs = @input_channels.map do |input_channel|
          @instance.rpop(input_channel)
        end

        @input_locks.each do |input_lock|
          @instance.set(input_lock, 0)
        end

        @instance.set(@input_overall_lock, 0)
        break
      end
    end

    return inputs
  end
end
