class Cachy
  WHILE_RUNNING_TMEOUT = 5*60 #seconds
  KEY_VERSION_TIMEOUT = 30 #seconds

  def self.cache(*args)
    key = key(*args)
    options = extract_options!(args)

    # Cached result?
    result = cache_store.read(key) and return result

    # Calculate result!
    set_while_running(key, options)

    result = yield
    cache_store.write key, result, options
    result
  end

  def self.key(*args)
    args = args.dup
    options = extract_options!(args)
    ensure_valid_keys options

    (args + meta_key_parts(args.first, options)).compact.map do |part|
      if part.respond_to? :cache_key
        part.cache_key
      else
        part
      end
    end * "_"
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
    if key_versions_expired?
      versions = cache_store.read("cachy_key_versions") || {}
      @@key_versions = {:versions=>versions, :last_set=>Time.now.to_i}
    end
    @@key_versions[:versions]
  end

  def self.key_versions=(data)
    @@key_versions[:last_set] = 0 #expire current key
    cache_store.write("cachy_key_versions", data)
  end

  def self.key_versions_expired?
    key_versions_timeout = Time.now.to_i - KEY_VERSION_TIMEOUT
    @@key_versions[:last_set] < key_versions_timeout
  end

  def self.increment_key(key)
    key = key.to_sym
    version = key_versions[key] || 0
    version += 1
    self.key_versions = key_versions.merge(key => version)
    version
  end

  # cache_store
  def self.cache_store=(x)
    @cache_store=x
  end

  def self.cache_store
    @cache_store || raise("Use: Cachy.cache_store = your_cache_store")
  end

  self.cache_store = ActionController::Base.cache_store if defined? ActionController::Base

  # locales
  class << self
    attr_accessor :locales
  end

  self.locales = if defined?(I18n) and I18n.respond_to?(:available_locales)
    I18n.available_locales
  else
    []
  end

  private

  # Temorarily store something else in the cache,
  # so that a often-called and slow cache-block is not run by
  # multiple processes in parallel
  def self.set_while_running(key, options)
    return unless options.key? :while_running
    warn "You cannot set while_running to nil or false" unless options[:while_running]
    cache_store.write key, options[:while_running], :expires_in=>WHILE_RUNNING_TMEOUT
  end

  def self.meta_key_parts(key, options)
    unless [String, Symbol].include?(key.class)
      raise ":key must be first argument of Cachy.cache / .key call"
    end

    parts = []
    parts << "v#{key_version_for(key)}"
    parts << global_cache_version
    parts << (options[:locale] || locale) unless options[:without_locale]

    keys = [*options[:keys]].compact # .to_a without warning
    parts += keys.map{ |k| "#{k}v#{key_version_for(k)}" }
    parts
  end

  def self.key_version_for(key)
    key = key.to_sym
    key_versions[key] || increment_key(key)
  end

  def self.ensure_valid_keys(options)
    invalid = options.keys - [:keys, :expires_in, :without_locale, :locale, :while_running]
    raise "unknown keys #{invalid.inspect}" unless invalid.empty?
  end

  # meta_key helpers
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