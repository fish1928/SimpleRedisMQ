require 'redis'
require 'helpers/simple_redis_mq_helper'
require 'helpers/multi_redis_mq_helper'

redis = Redis.new(host: '10.161.188.98')
redis.flushall

class SimplePusher
  def initialize(name, redis, output_channel)
    @name  = name
    @redis = redis
    @output_channel = output_channel
    @init_message = -1
  end

  def push_message
    @redis.rpush(@output_channel, "#{@name}_#{@init_message += 1}")
  end
end

level1_channels = (1..3).map {|i| "channel_#{i}"}
level2_channels = %w(12, 23, 1, 2, 3)

mq_12 = MultiRedisMQHelper.new("mq12", "10.161.188.98", '6379', %w(channel_1 channel_2), "12")
mq_12_2 = MultiRedisMQHelper.new("mq12", "10.161.188.98", '6379', %w(channel_1 channel_2), "12")
mq_23 = MultiRedisMQHelper.new("mq23", "10.161.188.98", '6379', %w(channel_2 channel_3), "23")
mq_23_2 = MultiRedisMQHelper.new("mq23", "10.161.188.98", '6379', %w(channel_2 channel_3), "23")
multi_mqs = [mq_12, mq_23, mq_12_2, mq_23_2]
#multi_mqs = [mq_12]

mq_1 = SimpleRedisMQHelper.new("mq1", "10.161.188.98", "6379", "channel_1", "1")
mq_2 = SimpleRedisMQHelper.new("mq2", "10.161.188.98", "6379", "channel_2", "2")
mq_3 = SimpleRedisMQHelper.new("mq3", "10.161.188.98", "6379", "channel_3", "3")
single_mqs = [mq_1, mq_2, mq_3]

pushers = (1..3).map do |i|
  SimplePusher.new("pusher_#{i}", redis, "channel_#{i}")
end

all_threads = []
message = 0

pusher_threads = pushers.map do |pusher|
  Thread.new do
    while true
      pusher.push_message
      sleep(1.3)
    end
  end
end

all_threads += pusher_threads
puts "pusher standby"

muti_threads = multi_mqs.map do |muti_mq|
  Thread.new do
    while true
      message = muti_mq.pop_input!
      muti_mq.push_output!(message)
      #sleep(0.1)
    end
  end
end

all_threads += muti_threads
puts "muti mqs standby"

single_threads = single_mqs.map do |single_mq|
  Thread.new do
    while true
      message = single_mq.pop_input!
      single_mq.push_output!(message)
      sleep(0.1)
    end
  end
end

all_threads += single_threads
puts "single mqs standby"

all_threads.each(&:join)
