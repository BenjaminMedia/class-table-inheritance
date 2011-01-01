spec = Gem::Specification.new do |s| 
  s.name = "class-table-inheritance"
  s.description = "ActiveRecord plugin designed to allow class table inheritance."
  s.summary = "ActiveRecord plugin designed to allow class table inheritance."
  s.version = "1.3.0"
  s.author = "Bruno Frank Cordeiro"
  s.email = "bfscordeiro@gmail.com"
  s.platform = Gem::Platform::RUBY
  s.files = Dir.glob('**/*') - ['class-table-inheritance.gemspec']
  s.require_path = "lib"  
  s.has_rdoc = false
  s.extra_rdoc_files = ["README"]
end
