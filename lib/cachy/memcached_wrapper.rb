require 'cachy/wrapper'

# Wrapper for Memcached
class Cachy::MemcachedWrapper < Cachy::Wrapper
  def write(key, result, options={})
    @wrapped.set(key, result, options[:expires_in].to_i)
  end
end