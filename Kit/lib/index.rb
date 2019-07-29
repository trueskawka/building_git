require "set"

require_relative "./index/entry"
require_relative "./index/checksum"
require_relative "./lockfile"

# manage the list of cache entries
class Index
  Invalid = Class.new(StandardError)
  # 4-byte string followed by two 32-bit big-endian numbers
  # (most significant bit first)
  HEADER_FORMAT = "a4N2"
  HEADER_SIZE   = 12
  SIGNATURE     = "DIRC"
  VERSION       = 2

  def initialize(pathname)
    @pathname = pathname
    @lockfile = Lockfile.new(pathname)
    clear
  end

  def load_for_update
    # acquire a lock on the file
    if @lockfile.hold_for_update
      load
      true
    else
      false 
    end
  end

  def load
    clear
    file = open_index_file
    puts file
    
    if file
      reader = Checksum.new(file)
      count = read_header(reader)
      read_entries(reader, count)
      reader.verify_checksum
    end
    
  ensure 
    file&.close
  end

  def add(pathname, oid, stat)
    entry = Entry.create(pathname, oid, stat)
    store_entry(entry)
    @changed = true
  end

  # iterate over entries in the sorted order
  def each_entry
    if block_given?
      @keys.each { |key| yield @entries[key] } 
    else
      enum_for(:each_entry) 
    end
  end

  def write_updates
    # skip all the work if there are no changes
    return @lockfile.rollback unless @changed

    writer = Checksum.new(@lockfile)
    
    header = [SIGNATURE, VERSION, @entries.size].pack(HEADER_FORMAT)
    writer.write(header)
    each_entry{ |entry| writer.write(entry.to_s) }
    
    writer.write_checksum
    @lockfile.commit

    # all changes have been written
    @changed = false
  end

  private

  # reset memory state
  def clear
    @entries = {}
    @keys    = SortedSet.new
    @changed = false
  end

  def store_entry(entry) 
    @keys.add(entry.key) 
    @entries[entry.key] = entry
  end

  def open_index_file
    puts @pathname
    File.open(@pathname, File::RDONLY)
    # not an error as it can happen reasonably
  rescue Errno::ENOENT
    nil
  end

  def read_header(reader)
    data = reader.read(HEADER_SIZE)
    signature, version, count = data.unpack(HEADER_FORMAT)
    
    unless signature == SIGNATURE
      raise Invalid, "Signature: expected '#{ SIGNATURE }' but found '#{ signature }'"
    end
    
    unless version == VERSION
      raise Invalid, "Version: expected '#{ VERSION }' but found '#{ version }'"
    end

    count
  end

  # read entries from disk to the in-memory @entries structure
  def read_entries(reader, count)
    count.times do
      # first read minimum entry
      entry = reader.read(ENTRY_MIN_SIZE)
    
      # read until a null byte is found
      until entry.byteslice(-1) == "\0" 
        entry.concat(reader.read(ENTRY_BLOCK))
      end
    
      # store
      store_entry(Entry.parse(entry)) 
    end
  end
end