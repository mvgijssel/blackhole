require './lib/blackhole'

# create a new blackhole
b = BlackHole.new

# raises error
b.foo = 'asd'
b.bar = 'asd'
b.baz = 'asd'


b.each do |name, value|

  puts "#{name}: #{value}"

end