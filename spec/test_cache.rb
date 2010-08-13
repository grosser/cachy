class TestCache
  def initialize
    @data = {}
  end

  def read(name)
    @data[name]
  end

  def read_multi(names)
    to_hash names.map{|n| [n,read(n)] }
  end

  def write(name, value, options = nil)
    @data[name] = value.freeze
  end

  def delete(name, options = nil)
    @data.delete(name)
  end

  def clear
    @data.clear
  end

  def keys
    @data.keys
  end

  private

  def to_hash(array)
    hash = {}
    array.each{|k,v| hash[k]=v}
    hash
  end
end