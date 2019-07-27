require "fileutils"
require "pathname"

require_relative "./blob"
require_relative "./database"
require_relative "./entry"
require_relative "./tree"
require_relative "./workspace"

# remove and return the first item from CLI arguments
command = ARGV.shift

case command 
# if the command is init
when "init"
  # if there is anotherargument, fetch it
  # otherwise return a default (working directory)
  path = ARGV.fetch(0, Dir.getwd)

  # convert a relative path to absolute one
  # then wrap it in a Pathname object that has methods for path manipulation
  # it's better to use data type specific methods for manipulation
  # than working with strings
  root_path = Pathname.new(File.expand_path(path))
  # add /.git to the resulting path
  git_path = root_path.join(".git")

  ["objects", "refs"].each do |dir|
    begin
      # create a directory with the name
      # mkdir_p is like `mkdir -p` that creates the directory
      # alongside any parent directories needed
      FileUtils.mkdir_p(git_path.join(dir))
    # if the script doesn't have permissions, throw
    # Errno is a namespace for operating system calls
    # Ruby mimics standard C constants for them
    rescue Errno::EACCES => error
      # use the stderr stream to report the error to the user
      # puts by itself sends the output to stdout
      $stderr.puts "fatal: #{ error.message }"
      exit 1
    end
  end
  
  puts "Initialized empty Kit repository in #{ git_path }"
  exit 0

when "commit"
  # assume working directory is the repo location
  root_path = Pathname.new(Dir.getwd)
  git_path  = root_path.join(".git")
  db_path   = git_path.join("objects")
  
  # list the files in a directory with the Workspace
  # Workspace class is responsible for files in the working tree
  workspace = Workspace.new(root_path)
  database  = Database.new(db_path)

  entries = workspace.list_files.map do |path|
    data = workspace.read_file(path)
    # wrap a string thhat we got by reading a file
    blob = Blob.new(data)
    
    database.store(blob)

    Entry.new(path, blob.oid)
  end

  tree = Tree.new(entries)
  database.store(tree)

  puts "tree: #{ tree.oid }"

# if the command is not init
else
  $stderr.puts "kit: '#{ command }' is not a kit command."
  exit 1
end