class Cachy::Wrapper
  def initialize(wrapped)
    @wrapped = wrapped
  end

  def read(key)
    @wrapped[key]
  end

  def read_multi(keys)
    if @wrapped.respond_to?(:read_multi)
      @wrapped.read_multi(keys)
    else
      to_hash keys.map{|k| [k,read(k)] }
    end
  end

  def method_missing(name, args)
    @wrapped.send(name, *args)
  end

  def respond_to?(x)
    super(x) || @wrapped.respond_to?(x)
  end

  private

  def to_hash(array)
    hash = {}
    array.each{|k,v| hash[k]=v}
    hash
  end
end