Caching library to simplify and organize caching.

 - I18n (seperate caches by locale / expires all locales)
 - Generation based (your able expire all caches of one type)
 - Simultanouse caching (handle multiple processes trying to write same expensive cache at once)
 - Dependent caches (x caches result of cache z+y -> z changes -> x changes)
 - Hashed keys (optional -> short/unreadable)
 - Global cache_version (expire everything Cachy cached, but not e.g. sessions)
 - ...
 - works out of the box with Rails
 - works with pure Memcache and [Moneta](http://github.com/wycats/moneta/tree/master)(-> Tokyo Cabinet / CouchDB / S3 / Berkeley DB / DataMapper / Memory store)

Install
=======
As Gem: ` sudo gem install cachy `
Or as Rails plugin: ` script/plugins install git://github.com/grosser/cachy.git `

Usage
=====
###Cachy.cache
    result = Cachy.cache(:a_key){ expensive() }
    result = Cachy.cache(:a_key, :expires_in => 1.minute){ expensive() }
    result = Cachy.cache(:a_key, 'something else', Date.today.day){ expensive() }

####Cache expensive operation that is run many times by many processes
Example: at application startup 20 processes try to set the same cache -> 20 heavy database requests -> database timeout -> cache still empty -> ... -> death

    # 19 Processes get [], 1 makes the request -- when cached all get the same result
    result = Cachy.cache(:a_key, :while_running=>[]){ block_db_for_5_seconds }


####Seperate version for each key
Expire all all caches of one kind when code inside the cache has been updated

    100.times{ Cachy.cache(:a_key, rand(100000) ){ expensive() } }
    Cachy.increment_key(:a_key) --> everything expired


####Uses I18n.locale if available
    Cachy.cache(:a_key){ 'English' }
    I18n.locale = :de
    Cachy.cache(:a_key){ 'German' } != 'English'

####Explicitly not use I18n.locale
    Cachy.cache(:a_key, :witout_locale=>true){ 'English' }
    I18n.locale = :de
    Cachy.cache(:a_key, :witout_locale=>true){ 'German' } == 'English'

####Caching results of other caches
When inner cache is expired outer cache would normally still shows old results.  
--> expire outer cache when inner cache is expired.

    a = Cachy.cache(:a, :expires_in=>1.day){ expensive() }
    b = Cachy.cache(:b, :expires_in=>1.week){ expensive_2() }
    Cachy.cache(:surrounding, :expires_in=>5.hours, :keys=>[:a, :b]){ a + b * c }
    Cachy.increment_key(:b) -->  expires :b and :surrounding

####Hashing keys
In case they get to long for your caching backend, makes them short but unreadable.

    Cachy.hash_keys = true  # global
    Cachy.cache(:a_key, :hash_key=>true){ expensive } # per call

#### Uses .cache_key when available
E.g. ActiveRecord objects are stored in the key with their updated_at timestamp.  
When they are updated the cache is automatically expired.

    Cachy.cache(:my_key, User.first){ expensive }

#### Uses CACHE_VERSION if defined
Use a global `CACHE_VERSION=1` so that all caches can be expired when something big changes.
The cache server does not need to be restarted and session data(Rails) is saved.


#### Does not cache nil
If you want to cache a falsy result, use false (same goes for :while_running)
    Cachy.cache(:x){ expensive || false }
    Cachy.cache(:x, :while_running=>false){ expensive }

###Cachy.expire / .expire_view
Expires all locales of a key
    Cachy.locales = [:de, :en] # by default filled with I18n.available_locales
    Cachy.expire(:my_key) -> expires for :de, :en and no-locale

    #expire "views/#{key}" (counterpart for Rails-view-caching)
    Cachy.expire_view(:my_key)
    Cachy.expire(:my_key, :prefix=>'views/')


###Cachy.key
Use to cache e.g. Erb output
    <% cache Cachy.key(:a_key), :expires_in=>1.hour do %>
      More html ...
    <% end %>


###Cachy.cache_store
No ActionController::Base.cache_store ?  
Give me something that responds to read/write(Rails style) or []/store([Moneta](http://github.com/wycats/moneta/tree/master)) or get/set(Memcached)
    Cachy.cache_store = some_cache


###Cachy.locales
No I18n.available_locales ?
    Cachy.locales = [:de, :en, :fr]

TODO
====
 - optionally store dependent keys (:keys=>xxx), so that they can be setup up once and do not need to be remembered

Authors
=======

###Contributors
 - [mindreframer](http://www.simplewebapp.de/roman)

[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...