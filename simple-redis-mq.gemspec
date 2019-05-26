Gem::Specification.new do |s|
  s.name        = 'simple-redis-mq'
  s.version     = '0.1.0'
  s.date        = '2019-05-16'
  s.summary     = "lib/helpers/simple_redis_mq_helper"
  s.description = "one 1-to-1 mq, one *-to-1 mq"
  s.authors     = ["Yukai Jin"]
  s.email       = 'fish1928@outlook.com'
  s.homepage    = 'https://github.com/fish1928/SimpleRedisMQ'
  s.files       = Dir['lib/**/*.rb']
  s.license     = 'MIT'
	s.add_runtime_dependency 'redis'
end
