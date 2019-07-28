class Index
  # N10 - ten 32-bit unsigned big-endian numbers
  # H40 - 40-char hex string
  # n - 16-bit unsigned endian number
  # Z* - null-terminated string
  ENTRY_FORMAT = "N10H40nZ*"
  ENTRY_BLOCK = 8

  # octal numbers, stored as numbers
  REGULAR_MODE    = 0100644 
  EXECUTABLE_MODE = 0100755
  # hexadecimal
  MAX_PATH_SIZE   = 0xfff

  entry_fields = [
    :ctime, :ctime_nsec,
    :mtime, :mtime_nsec,
    :dev, :ino, :mode, :uid, :gid, :size,
    :oid, :flags, :path
  ]

  Entry = Struct.new(*entry_fields) do 
    def self.create(pathname, oid, stat)
      path  = pathname.to_s
      mode  = stat.executable? ? EXECUTABLE_MODE : REGULAR_MODE
      # store the path length to make parsing easier
      # entries are padded to be multiples of 8
      # so it can step 8 bytes at a time
      flags = [path.bytesize, MAX_PATH_SIZE].min
  
      Entry.new(
        stat.ctime.to_i, stat.ctime.nsec,
        stat.mtime.to_i, stat.mtime.nsec,
        stat.dev, stat.ino, mode, stat.uid, stat.gid, stat.size, 
        oid, flags, path)
    end 

    def to_s
      # return an array of te values of string fields
      # in the order defined in Struct.new
      string = to_a.pack(ENTRY_FORMAT)
      # pad the string wit null bytes until the size is a multiple of 8
      # there must be at least 1 null byte
      string.concat("\0") until string.bytesize % ENTRY_BLOCK == 0
      string
    end
  end
end