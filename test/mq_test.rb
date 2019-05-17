require 'helpers/simple_redis_mq_helper'

Redis.new(host: '10.192.102.194').flushall

level_1_input = 'level_1_input_channel'
level_1_output = 'level_1_output_channel'

level_2_input = level_1_output
level_2_output = 'level_2_output_channel'


i = 0
j = 0
level1_listeners = 3.times.map do
  j += 1
  j1 = j
  Thread.new do

    i1 = i
    k = 0
    worker_name = "worker-#{i1}-#{j1}"
    helper = SimpleRedisMQHelper.new(worker_name, '10.192.102.194', '6379', level_1_input, level_1_output)

    while true
      puts "#{worker_name} working.."

      k += 1
      k1 = k
      input = helper.pop_input!
      puts "#{worker_name} handling #{input}"
      output = "#{input}_#{i1}#{j1}#{k1}"
      helper.push_output!(output)
    end
  end
end
sleep(1)

i = 1
j = 0
level2_listener = 5.times.map do
  j += 1
  j2 = j

  Thread.new do
    i2 = i
    worker_name = "worker-#{i2}-#{j2}"
    helper = SimpleRedisMQHelper.new(worker_name, '10.192.102.194', '6379', level_2_input, level_2_output)
    k = 0

    while true
      puts "#{worker_name} working.."
      k += 1
      k2 = k
      input = helper.pop_input!
      output = "#{input}_#{i2}#{j2}#{k2}"
      helper.push_output!(output)
    end
  end
end

(level1_listeners + level2_listener).each(&:join)
#puts done
