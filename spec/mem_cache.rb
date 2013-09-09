# stub to test memcache integration
class MemCache
  def initialize
    @wrapped = {}
  end

  def set(key, object, ttl = nil)
    raise 'nope!' if ttl.is_a? Hash or (ttl and not ttl.is_a? Numeric)
    @wrapped[key] = object
  end

  def get(key)
    cache_get(key)
  end

  def cache_get(key)
    stubable_cache_get(key)
  end

  def stubable_cache_get(key)
    @wrapped[key]
  end

  def clear
    @wrapped.clear
  end

  def delete(key)
    @wrapped.delete(key)
  end
end