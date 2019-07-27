require "digest/sha1"
require "zlib"

require_relative "./blob"

class Database
  TEMP_CHARS = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a

  def initialize(pathname)
    @pathname = pathname 
  end

  def store(object)
    # represents arbitrary binary data
    string = object.to_s.force_encoding(Encoding::ASCII_8BIT)
    # create content by appending type, size, null bit and content
    content = "#{ object.type } #{ string.bytesize }\0#{ string }"
    
    # apply SHA-1 to content to generate ID
    object.oid = Digest::SHA1.hexdigest(content)
    # write object at generated ID
    write_object(object.oid, content) 
  end

  def write_object(oid, content)
    # build the blob desitination path
    object_path = @pathname.join(oid[0..1], oid[2..-1])
    return if File.exist?(object_path)
    # get directory name
    # could've done it with string manipulation, but that's hard to read
    # and brittle - better to use built-ins
    dirname     = object_path.dirname
    # have a temporary path for writing the object
    temp_path   = dirname.join(generate_temp_name)
    
    begin
      # underlying C system libraries
      # RDWR - open for reading and writing
      # CREAT - OS will attempt to creat the file if it doesn't exist
      # EXCL - an error will be thrown if the file exists (don't clash the
      # random filenaes)
      # it CREAT! it TRUNC!
      flags = File::RDWR | File::CREAT | File::EXCL
      file  = File.open(temp_path, flags)
    rescue Errno::ENOENT
      Dir.mkdir(dirname)
      file = File.open(temp_path, flags)
    end
    
    compressed = Zlib::Deflate.deflate(content, Zlib::BEST_SPEED)
    file.write(compressed)
    file.close

    File.rename(temp_path, object_path) 
  end

  def generate_temp_name
    # generate a random filename in the same directory as the blob path
    # array sample method selects from array at random
    "tmp_obj_#{ (1..6).map { TEMP_CHARS.sample }.join("") }"
  end
end