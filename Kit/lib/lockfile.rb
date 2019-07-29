class Lockfile
  MissingParent = Class.new(StandardError)
  NoPermission = Class.new(StandardError)
  StaleLock = Class.new(StandardError)

  # initialize with the path of the file to be updated
  def initialize(path)
    @file_path = path
    @lock_path = path.sub_ext(".lock")

    @lock = nil
  end

  def hold_for_update 
    unless @lock
      # create if it doesn't exist, error if it does
      # doing it in one call makes it atomic - no running instance
      # can first do a check and then do something
      # underlying C system libraries
      # RDWR - open for reading and writing
      # CREAT - OS will attempt to creat the file if it doesn't exist
      # EXCL - an error will be thrown if the file exists
      flags = File::RDWR | File::CREAT | File::EXCL
      @lock = File.open(@lock_path, flags)
    end
    true
    
  # catch file already exists
  rescue Errno::EEXIST
    false
  # if the parent directory doesn't exist
  # catch and convert
  rescue Errno::ENOENT => error
    raise MissingParent, error.message
  rescue Errno::EACCES => error
    raise NoPermission, error.message
  end

  # write to the lock file
  def write(string)
    # puts @lock_path
    # puts @lock
    raise_on_stale_lock
    @lock.write(string)
  end

  # close the lock file
  # rename it
  # remove lock
  def commit
    raise_on_stale_lock

    @lock.close
    File.rename(@lock_path, @file_path)
    @lock = nil
  end

  # remove the lockfile and free the lock
  def rollback
    raise_on_stale_lock
    
    @lock.close
    File.unlink(@lock_path)
    @lock = nil
  end

  private
  
  # if the lock has been released or not acquired - throw
  def raise_on_stale_lock
    unless @lock
      raise StaleLock, "Not holding lock on file: #{ @lock_path }"
    end
  end
end