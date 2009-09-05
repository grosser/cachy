class Cachy
  KEY_VERSION_TIMEOUT = 30 #seconds

  def self.cache(*args)
    key = key(*args)
    options = extract_options!(args)

    #already cached?
    result = cache_store.read key
    return result if result

    #for long queries, store something else in the cache, so that a often-called cache is not filled by multiple callers
    cache_store.write key, options[:while_running], 5*60 if options[:while_running]
    
    result = yield

    #setting with nil causes errors in the next get/set request
    if options[:expires_in]
      cache_store.write(key, result, :expires_in=>options[:expires_in])
    else
      cache_store.write(key, result)
    end

    result
  end

  def self.key(*args)
    args_to_key(args)
  end

  def self.expire(*args)
    args = args.dup
    options = extract_options!(args)

    (locales+[false]).each do |locale|
      without_locale = (locale==false)
      args_with_locale = args + [options.merge(:locale=>locale, :without_locale=>without_locale)]
      cache_store.delete key(*args_with_locale)
    end
  end

  @@key_versions = {:versions=>{}, :last_set=>0}
  def self.key_versions
    if @@key_versions[:last_set] > (Time.now.to_i - KEY_VERSION_TIMEOUT)
      @@key_versions[:versions]
    else
      cached = cache_store.read("cachy_key_versions") || {}
      @@key_versions = {:versions=>cached, :last_set=>Time.now.to_i}
      cached
    end
  end

  def self.key_versions=(data)
    @@key_versions[:last_set] = 0 #expire current key
    cache_store.write("cachy_key_versions", data)
  end

  def self.increment_key(key)
    key = key.to_sym
    version = key_versions[key] || 0
    version += 1
    self.key_versions = key_versions.merge(key => version)
    version
  end

  def self.cache_store
    @@cache_store || raise("Use: Cachy.cache_store = your_cache_store")
  end

  def self.cache_store=(x)
    @@cache_store=x
  end

  # fill cache_store with Rails cache when present
  if defined? ActionController::Base
    @@cache_store = ActionController::Base.cache_store
  end

  def self.locales
    @@locales
  end

  def self.locales=(x)
    @@locales = x
  end

  # fill locales with defauls
  @@locales = if defined?(I18n) and I18n.respond_to?(:available_locales)
    I18n.available_locales
  else
    []
  end

  private

  def self.key_version_for(key)
    key = key.to_sym
    key_versions[key] || increment_key(key)
  end

  def self.args_to_key(args)
    args = args.dup
    options = extract_options!(args)
    ensure_valid_keys options

    raise "key must be at first position" unless [String, Symbol].include?(args.first.class)
    
    args << "v#{key_version_for(args.first)}"
    args << global_cache_version
    args << (options[:locale] || locale) unless options[:without_locale]

    keys = [*options[:keys]].compact # .to_a without warning
    args += keys.map{ |key| "#{key}v#{key_version_for(key)}" }

    args.compact.map do |item|
      if item.respond_to? :cache_key
        item.cache_key
      else
        item
      end
    end * "_"
  end

  def self.ensure_valid_keys(options)
    invalid = options.keys - [:keys, :expires_in, :without_locale, :locale, :while_running]
    raise "unknown keys #{invalid.inspect}" unless invalid.empty?
  end

  #Helpers
  def self.global_cache_version
    defined?(CACHE_VERSION) ? CACHE_VERSION : nil
  end

  def self.locale
    (defined?(I18n) and I18n.respond_to?(:locale)) ? I18n.locale : nil
  end

  def self.extract_options!(args)
    if args.last.is_a? Hash
      args.pop
    else
      {}
    end
  end
end