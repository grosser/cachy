# do not let MemCache timeouts kill your app,
# mark as error and return read_error_callback (e.g. nil -> cache miss)
MemCache # class should exist at this point

class MemCache
  # Add your callback to stop timeouts from raising
  #
  # MemCache.read_error_callback = lambda{|error|
  #   error.message << ' -- catched'
  #   HoptoadNotifier.notify error
  #   nil
  # }

  class << self
    attr_accessor :read_error_callback
  end
  attr_accessor :read_error_occurred

  def cache_get_with_timeout_protection(*args)
    begin
      @read_error_occurred = false
      cache_get_without_timeout_protection(*args)
    rescue Exception => error
      @read_error_occurred = true
      if error.to_s == 'IO timeout' and self.class.read_error_callback
        self.class.read_error_callback.call error
      else
        raise error
      end
    end
  end

  alias_method :cache_get_without_timeout_protection, :cache_get
  alias_method :cache_get, :cache_get_with_timeout_protection
end