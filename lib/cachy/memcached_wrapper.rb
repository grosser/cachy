require 'cachy/wrapper'

class Cachy::MemcachedWrapper < Cachy::Wrapper
  def read(key)
    @wrapped.get(key)
  end

  def write(key, result, options={})
    @wrapped.set(key, result, options[:expires_in].to_i)
  end
end