require "digest/sha1"

require_relative "./index/entry"
require_relative "./lockfile"

# manage the list of cache entries
class Index
  # 4-byte string followed by two 32-bit big-endian numbers
  # (most significant bit first)
  HEADER_FORMAT = "a4N2"

  def initialize(pathname)
    @entries = {}
    @lockfile = Lockfile.new(pathname) 
  end

  def write_updates
    return false unless @lockfile.hold_for_update
    
    begin_write
    # serialize the header data
    header = ["DIRC", 2, @entries.size].pack(HEADER_FORMAT)
    write(header)
    @entries.each { |key, entry| write(entry.to_s) }
    finish_write

    true 
  end

  def add(pathname, oid, stat)
    entry = Entry.create(pathname, oid, stat)
    @entries[pathname.to_s] = entry
  end

  # add content to Digest so we can SHA-1 the index
  # SHA-1 can be incremental
  def begin_write
    @digest = Digest::SHA1.new
  end
  
  def write(data) 
    @lockfile.write(data) 
    @digest.update(data)
  end
    
  def finish_write 
    @lockfile.write(@digest.digest) 
    @lockfile.commit
  end
end