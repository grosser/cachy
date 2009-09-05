class Cachy
  KEY_VERSION_TIMEOUT = 30 #seconds

  def self.cache(*args)
    options = args.extract_options!
    key = key(*(args + [options]))

    #already cached?
    result = CACHE.get key
    return result if result

    #for long queries, store something else in the cache, so that a often-called cache is not filled by multiple callers
    CACHE.set key, options[:while_running], 5*60 if options[:while_running]
    
    result = yield

    #setting with nil causes errors in the next get/set request
    if options[:expires_in]
      CACHE.set key, result, options[:expires_in]
    else
      CACHE.set key, result
    end

    result
  end

  def self.key(*args)
    args_to_key(args)
  end

  def self.expire(*args)
    $LANGUAGES.each do |l|
      I18n.with_locale(l) do
        CACHE.delete key(*args)
      end
    end
  end

  @@key_versions = {:versions=>{}, :last_set=>0}
  def self.key_versions
    if @@key_versions[:last_set] > KEY_VERSION_TIMEOUT.ago
      @@key_versions[:versions]
    else
      cached = CACHE["cachy_key_versions"] || {}
      @@key_versions = {:versions=>cached, :last_set=>Time.now}
      cached
    end
  end

  def self.key_versions=(data)
    @@key_versions[:last_set] = 0 #expire current key
    CACHE["cachy_key_versions"] = data
  end

  def self.increment_key(key)
    key = key.to_sym
    version = key_versions[key] || 0
    version += 1
    self.key_versions = key_versions.merge(key => version)
    version
  end

  private

  def self.global_cache_version
    defined? CACHE_VERSION ? CACHE_VERSION : nil
  end

  def self.locale
    (defined?(I18n) and I18n.respond_to?(:locale)) ? I18n.locale : nil
  end

  def self.key_version_for(key)
    key = key.to_sym
    key_versions[key] || increment_key(key)
  end

  def self.args_to_key(args)
    args = args.dup
    options = args.extract_options!
    ensure_valid_keys options
    
    raise "key must be at first position" unless [String, Symbol].include?(args.first.class)

    args << "v#{key_version_for(args.first)}"
    args << global_cache_version
    args << locale unless options[:without_locale]

    keys = [*options[:keys]] # .to_a without warning
    args += keys.map{ |key| "#{key}v#{key_version_for(key)}" }

    args.compact.map do |item|
      if item.responds_to? :cache_version
        item.cache_version
      else
        item
      end
    end * "_"
  end

  def self.ensure_valid_keys(options)
    invalid = options.keys - [:keys, :expires_in, :without_locale, :while_running]
    raise "unknown keys #{invalid.inspect}" unless invalid.empty?
  end
end