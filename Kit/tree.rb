class Tree
  # A7: encode mode as seven-byte string space-padded on the right
  # Z*: encode entry.name as an arbitrary-length null-padded string
  # H40: encode entry.oid as a string of forty hexadecimal digits
  ENTRY_FORMAT = "A7Z*H40"
  
  attr_accessor :oid
  
  def initialize(entries)
    @entries = entries
  end

  def type 
    "tree"
  end

  def to_s
    entries = @entries.sort_by(&:name).map do |entry|
      # sort entries by name and convert to string
      # Array#pack takes an array and returns a string representing values
      # the ENTRY_FORMAT defines how each value gets represented
      [entry.mode, entry.name, entry.oid].pack(ENTRY_FORMAT) 
    end

    entries.join("")
  end
 end