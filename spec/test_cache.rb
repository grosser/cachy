class TestCache
  def initialize
    @data = {}
  end

  def read(name)
    @data[name]
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
end