# We are going to try doing it this way. If it proves a problem
# we'll make a special class.
#
class TrueClass
  def empty?
    false
  end

  def &(other)
    other
  end

  def |(other)
    other
  end
end

#
class Array
  alias and_without_t :&
  alias or_without_t :|

  def |(other)
    TrueClass === other ? dup : or_without_t(other)
  end

  def &(other)
    TrueClass === other ? dup : and_without_t(other)
  end
end


=begin
class TrueArray < Array

  def each; end

  def size
    1  # ?
  end

  def empty?
    false
  end

  def &(other)
    other.dup
  end

  def |(other)
    other.dup
  end

  ## If this would have worked we would not have had
  ## to override Array.
  #def coerce(other)
  #  return self, other
  #end
end
=end

