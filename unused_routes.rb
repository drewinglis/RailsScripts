#!/Users/drew/.rvm/rubies/ruby-1.9.3-p125/bin/ruby

if ARGV.length == 0
  puts "USAGE: ./unused_routes.rb /path/to/rails/root"
  exit 0
end

rails_root = ARGV[0]

# assumes the hash contains only string or symbol values
def hash_from_string(str)
  if "{}" == str
    return {}
  else
    return str.gsub(/[{}:"']/,'').split(', ').map{|h| h1,h2 = h.split('=>'); {h1 => h2}}.reduce(:merge)
  end
end

routes = `rake routes`.split("\n").map {|line|
  hash_from_string(line.match(/(\{.*\})/)[1])
    .merge(:not_get => ["POST", "PUT", "DELETE"].inject(nil) { |mem, var|
        mem ||= line.match(var)
      })
}
view_files = `ls -l #{rails_root}app/views/ | awk '{ print "#{rails_root}app/views/" $9 }' | xargs ls`.split("\n\n")
views = {}

index = 1
while index < view_files.length
  tokens = view_files[index].split("\n")
  controller = tokens.shift.match(/app\/views\/(.*):/)[1]
  views[controller] = tokens unless tokens.nil?
  index += 1
end

excess_routes = []

routes.each do |route|
  unless route[:not_get]
    route_file_name = route["action"] + ".html.erb"
    if views[route["controller"]] && views[route["controller"]].include?(route_file_name)
      views[route["controller"]].delete(route_file_name)
    else
      excess_routes << route
    end
  end
end

puts "Unmatched view files:"
views.each_pair do |key,value|
  if [] != value
    puts "#{key}: #{value.to_s}"
  end
end

puts "Unmatched routes:"
puts excess_routes
