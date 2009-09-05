Caching library for projects that have many processes or many caches.  
(works out of the box when Rails is present)

Install
=======
As Gem: ` sudo gem install grosser-cachy -s http://gems.github.com `  
Or as Rails plugin: ` script/plugins install git://github.com/grosser/cachy.git `


Usage
=====
###Cache
    result = Cachy.cache(:a_key){ expensive() }
    result = Cachy.cache(:a_key, :expires_in => 1.minute){ expensive() }
    result = Cachy.cache(:a_key, 'something else', Date.today.day){ expensive() }

Cache expensive operation that is run many times by many processes

    # 20 Processes -> Instant database death
    result = Cachy.cache(:a_key){ block_db_for_5_seconds }

    # 19 Processes get [], 1 makes the request -- when finished all get the same cached result
    result = Cachy.cache(:a_key, :while_running=>[]){ block_db_for_5_seconds }


Seperate version for each key --> expire all all caches of one kind

    100.times{ Cachy.cache(:a_key, rand(100000) ){ expensive() } }
    Cachy.increment_key(:a_key) --> everything expired


Uses I18n.locale if available
    Cachy.cache(:a_key){ 'English' }
    I18n.locale = :de
    Cachy.cache(:a_key){ 'German' } != 'English'

Explicitly not use I18n.locale
    Cachy.cache(:a_key, :witout_locale=>true){ 'English' }
    I18n.locale = :de
    Cachy.cache(:a_key, :witout_locale=>true){ 'German' } == 'English'

Caching something that is already cached.
    a = Cachy.cache(:a, :expires_in=>1.day){ expensive() }
    b = Cachy.cache(:b, :expires_in=>1.week){ expensive_2() }
    Cachy.cache(:surrounding, :expires_in=>5.hours, :keys=>[:a, :b]){ a + b * c }
    Cachy.increment_key(:b) -->  expires :b and :surrounding


Uses CACHE_VERSION if available  
Uses .cache_key when available e.g. for ActiveRecord objects


###Key
Use to cache e.g. Erb output
    <% cache Cachy.key(:a_key), :expires_in=>1.hour do %>
      More html ...
    <% end %>

###Hash keys
When your keys get to long(e.g. MemChached complains) they can be hashed (makes them unreadable but short)
    Cachy.hash_keys = true  # global
    Cachy.cache(:a_key, :hash_key=>true) # for single cache

###Cache_store
No ActionController::Base.cache_store ?
Give me something that responds to read/write(Rails style) or []/store(Moneta) or get/set(Memcached)
    Cachy.cache_store = some_cache

Author
======
[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...