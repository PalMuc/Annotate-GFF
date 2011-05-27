if RUBY_PLATFORM =~ /java/
  puts "JRUBY!"
  command = "ruby -J-Xmx2g " + File.join(File.dirname(__FILE__), '..', 'lib/hello.rb')
  system(command)
else
  puts "MRI"
  command = "ruby " + File.join(File.dirname(__FILE__), '..', 'lib/hello.rb')
  system(command)
end

puts "Still there?"
