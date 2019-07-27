require "digest/sha1"
require "zlib"

# just the string
string = "hello\n"
puts "raw:"
puts Digest::SHA1.hexdigest(string)

# blob and bytesize - file SHA
blob = "blob #{ string.bytesize }\0#{ string }"
puts "blob:"
puts Digest::SHA1.hexdigest(blob)

# zipped
zipped = Zlib::Deflate.deflate(blob)
puts "zipped:"
puts Digest::SHA1.hexdigest(zipped)