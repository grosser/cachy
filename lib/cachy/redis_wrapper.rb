require 'cachy/wrapper'
require 'yaml'

class Cachy::RedisWrapper < Cachy::Wrapper
  def read(key)
    result = @wrapped.get(key)
    return if result.nil?
    YAML.load(result)
  end

  def write(key, value, options={})
    result = @wrapped.set(key, value.to_yaml)
    @wrapped.expire(key, options[:expires_in].to_i) if options[:expires_in]
    result
  end

  def delete(key)
    @wrapped.del(key)
  end
end
