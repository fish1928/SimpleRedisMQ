Gem::Specification.new do |s|
  s.name        = 'simple-redis-mq'
  s.version     = '0.0.1'
  s.date        = '2019-05-16'
  s.summary     = "lib/helpers/SimpleRedisMQHelper"
  s.description = "a simple redis mq helper, listen to one channel, push to another"
  s.authors     = ["Yukai Jin"]
  s.email       = 'fish1928@outlook.com'
  s.homepage    = 'https://github.com/fish1928/SimpleRedisMQHelper'
  s.files       = Dir['lib/**/*.rb']
  s.license     = 'MIT'
	s.add_runtime_dependency 'redis'
end
