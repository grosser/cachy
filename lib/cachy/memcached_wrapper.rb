require 'cachy/wrapper'

class Cachy::MemcachedWrapper < Cachy::Wrapper
  def write(key, result, options={})
    @wrapped.set(key, result, options[:expires_in].to_i)
  end
end