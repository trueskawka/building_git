require_relative "../entry"

class Database
  class Tree
    # Z*: encode entry.mode and name as an arbitrary-length null-padded string
    # H40: encode entry.oid as a string of forty hexadecimal digits
    ENTRY_FORMAT = "Z*H40"
    
    attr_accessor :oid
    
    def initialize
      @entries = {}
    end

    def type 
      "tree"
    end

    def mode
      Entry::DIRECTORY_MODE
    end

    def to_s
      entries = @entries.map do |name, entry|
        # sort entries by name and convert to string
        # Array#pack takes an array and returns a string representing values
        # the ENTRY_FORMAT defines how each value gets represented
        ["#{ entry.mode } #{ name }", entry.oid].pack(ENTRY_FORMAT) 
      end

      entries.join("")
    end

    def self.build(entries)
      # forcing a sort order ensures the hash will stay the same
      # Ruby sorts pathnames and strings differently
      # so in order to get the right sorting, we need to make them strings
      # Git first sorts the file list for the project, and then builds a tree
      entries = entries.sort_by { |entry| entry.name.to_s }
      root    = Tree.new
      
      entries.each do |entry|
        # iterator that yields each component of a pathname
        # to_a turns it into an array
        path = entry.name.each_filename.to_a
        # get the last element of the path
        name = path.pop
        root.add_entry(path, name, entry)
      end
      
      root
    end

    def add_entry(path, name, entry) 
      if path.empty?
        @entries[name] = entry 
      else
        # create a new tree with the first element of path
        # guarted ||= - nothing happens if it already exists
        tree = @entries[path.first] ||= Tree.new
        # add elements to the new tree
        tree.add_entry(path.drop(1), name, entry) 
      end
    end

    # needs to get the deepest subtree first
    # yield the root tree last
    def traverse(&block) 
      @entries.each do |name, entry|
        entry.traverse(&block) if entry.is_a?(Tree)
      end
      block.call(self)
    end
  end
end