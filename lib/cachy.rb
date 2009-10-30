class Cachy
  WHILE_RUNNING_TMEOUT = 5*60 #seconds
  KEY_VERSION_TIMEOUT = 30 #seconds

  # Cache the result of a block
  #
  # Cachy.cache(:my_key){ expensive() }
  # Cachy.cache(:my_key, :expires_in=>1.hour){ expensive() }
  # Cachy.cache(:my_key, :keys=>[:dependent_key]){ expensive() }
  # Cachy.cache(:my_key, :without_locale=>true){ expensive() }
  # Cachy.cache(:my_key, :hash_key=>true){ expensive() }
  def self.cache(*args)
    key = key(*args)
    options = extract_options!(args)

    # Cached result?
    result = cache_store.read(key)
    return result unless result == nil

    # Calculate result!
    set_while_running(key, options)

    result = yield
    cache_store.write key, result, options
    result
  end

  # Constructs a cache-key (first argument must be a String/Symbol)
  #
  # Cachy.key :my_key
  # Cachy.key :my_key, User.first, :locale=>:de
  # Cachy.key :my_key, User.first, :without_locale=>true, :hash_key=>true
  def self.key(*args)
    options = extract_options!(args)
    ensure_valid_keys options

    key = (args + meta_key_parts(args.first, options)).compact.map do |part|
      if part.respond_to? :cache_key
        part.cache_key
      else
        part
      end
    end * "_"

    key = (options[:hash_key] || hash_keys) ? hash(key) : key
    options[:prefix].to_s + key + options[:suffix].to_s
  end

  # Expire all possible locales of a cache, use the same arguments as with cache
  #
  # Cachy.expire(:my_key, User.first)
  # Cachy.expire(:my_key, User.first, :keys=>[:dependent_keys])
  # Cachy.expire(:my_key, :prefix=>'views/')
  def self.expire(*args)
    options = extract_options!(args)

    (locales+[false]).each do |locale|
      without_locale = (locale==false)
      args_with_locale = args + [options.merge(:locale=>locale, :without_locale=>without_locale)]
      cache_store.delete key(*args_with_locale)
    end
  end

  def self.expire_view(*args)
    options = extract_options!(args)
    args = args + [options.merge(:prefix=>'views/')]
    expire(*args)
  end

  # Fetch key_versions from cache every KEY_VERSION_TIMEOUT seconds,
  # otherwise every .key call would result in an cache request
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

  # Expires all caches that use this key
  def self.increment_key(key)
    key = key.to_sym
    version = key_versions[key] || 0
    version += 1
    self.key_versions = key_versions.merge(key => version)
    version
  end

  class << self
    attr_accessor :hash_keys
  end
  
  # Wrap non ActiveSupport style cache stores,
  # to get the same interface for all
  def self.cache_store=(x)
    if x.respond_to? :read and x.respond_to? :write
      @cache_store=x
    elsif x.respond_to? "[]" and x.respond_to? :set
      require 'cachy/memcached_wrapper'
      @cache_store = MemcachedWrapper.new(x)
    elsif x.respond_to? "[]" and x.respond_to? :store
      require 'cachy/moneta_wrapper'
      @cache_store = MonetaWrapper.new(x)
    else
      raise "This cache_store type is not usable for Cachy!"
    end
  end

  def self.cache_store
    @cache_store || raise("Use: Cachy.cache_store = your_cache_store")
  end

  self.cache_store = ActionController::Base.cache_store if defined? ActionController::Base

  # locales
  @@locales = nil
  def self.locales=(x)
    @@locales = x
  end

  def self.locales
    return @@locales if @@locales
    if defined?(I18n) and I18n.respond_to?(:available_locales)
      I18n.available_locales
    else
      []
    end
  end

  private

  # Do we need to fetch fresh key_versions from cache ?
  def self.key_versions_expired?
    key_versions_timeout = Time.now.to_i - KEY_VERSION_TIMEOUT
    @@key_versions[:last_set] < key_versions_timeout
  end

  # Temorarily store something else in the cache,
  # so that a often-called and slow cache-block is not run by
  # multiple processes in parallel
  def self.set_while_running(key, options)
    return unless options.key? :while_running
    warn "You cannot set while_running to nil" if options[:while_running] == nil
    cache_store.write key, options[:while_running], :expires_in=>WHILE_RUNNING_TMEOUT
  end

  def self.meta_key_parts(key, options)
    unless [String, Symbol].include?(key.class)
      raise ":key must be first argument of Cachy call"
    end

    parts = []
    parts << "v#{key_version_for(key)}"
    parts << global_cache_version
    parts << (options[:locale] || locale) unless options[:without_locale]

    keys = [*options[:keys]].compact # [*x] == .to_a without warnings
    parts += keys.map{|k| "#{k}v#{key_version_for(k)}" }
    parts
  end

  def self.key_version_for(key)
    key = key.to_sym
    key_versions[key] || increment_key(key)
  end

  def self.ensure_valid_keys(options)
    invalid = options.keys - [:keys, :expires_in, :without_locale, :locale, :while_running, :hash_key, :prefix, :suffix]
    raise "unknown keys #{invalid.inspect}" unless invalid.empty?
  end

  def self.hash(string)
    require "digest/md5"
    Digest::MD5.hexdigest(string)
  end

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