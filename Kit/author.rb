Author = Struct.new(:name, :email, :time) do
  def to_s
    # create a string from time.now value
    timestamp = time.strftime("%s %z")
    # encode name, email, and timestamp into a string
    "#{ name } <#{ email }> #{ timestamp }"
  end
 end