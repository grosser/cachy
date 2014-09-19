Caching library to simplify and organize caching.

 - I18n (seperate caches by locale / expires all locales)
 - Generation based (your able expire all caches of one type)
 - Simultanouse caching (handle multiple processes trying to write same expensive cache at once)
 - Dependent caches (x caches result of cache z+y -> z changes -> x changes)
 - Hashed keys (optional -> short/unreadable)
 - Global cache_version (expire everything Cachy cached, but not e.g. sessions)
 - ...
 - works out of the box with Rails
 - works with pure Memcache, Redis and [Moneta](http://github.com/wycats/moneta/tree/master)(-> Tokyo Cabinet / CouchDB / S3 / Berkeley DB / DataMapper / Memory store)

Install
=======

```Bash
gem install cachy
```

Usage
=====

### Cachy.cache

```Ruby
result = Cachy.cache(:a_key){ expensive() }
result = Cachy.cache(:a_key, :expires_in => 1.minute){ expensive() }
result = Cachy.cache(:a_key, 'something else', Date.today.day){ expensive() }
```

#### Cache expensive operation that is run many times by many processes
Example: at application startup 20 processes try to set the same cache -> 20 heavy database requests -> database timeout -> cache still empty -> ... -> death

```Ruby
# 19 Processes get [], 1 makes the request -- when cached all get the same result
result = Cachy.cache(:a_key, :while_running=>[]){ block_db_for_5_seconds }
```


#### Seperate version for each key
Expire all caches of one kind when code inside the cache has been updated

```Ruby
100.times{ Cachy.cache(:a_key, rand(100000) ){ expensive() } }
Cachy.increment_key(:a_key) --> everything expired
```


#### Uses I18n.locale if available

```Ruby
Cachy.cache(:a_key){ 'English' }
I18n.locale = :de
Cachy.cache(:a_key){ 'German' } != 'English'
```

#### Explicitly not use I18n.locale

```Ruby
Cachy.cache(:a_key, :witout_locale=>true){ 'English' }
I18n.locale = :de
Cachy.cache(:a_key, :witout_locale=>true){ 'German' } == 'English'
```

#### Caching results of other caches
When inner cache is expired outer cache would normally still shows old results.<br/>
--> expire outer cache when inner cache is expired.

```Ruby
a = Cachy.cache(:a, :expires_in=>1.day){ expensive() }
b = Cachy.cache(:b, :expires_in=>1.week){ expensive_2() }
Cachy.cache(:surrounding, :expires_in=>5.hours, :keys=>[:a, :b]){ a + b * c }
Cachy.increment_key(:b) -->  expires :b and :surrounding
```

#### Hashing keys
In case they get to long for your caching backend, makes them short but unreadable.

```Ruby
Cachy.hash_keys = true  # global
Cachy.cache(:a_key, :hash_key=>true){ expensive } # per call
```

#### Uses .cache_key when available
E.g. ActiveRecord objects are stored in the key with their updated_at timestamp.<br/>
When they are updated the cache is automatically expired.

```Ruby
Cachy.cache(:my_key, User.first){ expensive }
```

#### Uses CACHE_VERSION if defined
Use a global `CACHE_VERSION=1` so that all caches can be expired when something big changes.
The cache server does not need to be restarted and session data(Rails) is saved.

#### Does not cache nil
If you want to cache a falsy result, use false (same goes for :while_running)

```Ruby
Cachy.cache(:x){ expensive || false }
Cachy.cache(:x, :while_running=>false){ expensive }
```

### Cachy.cache_if
Only caches if condition is fulfilled

```Ruby
Cachy.cache_if(condition, :foo, 'bar', :expires_in => 1.minute){do_something}
```

### Cachy.expire / .expire_view
Expires all locales of a key

```Ruby
Cachy.locales = [:de, :en] # by default filled with I18n.available_locales
Cachy.expire(:my_key) -> expires for :de, :en and no-locale

#expire "views/#{key}" (counterpart for Rails-view-caching)
Cachy.expire_view(:my_key)
Cachy.expire(:my_key, :prefix=>'views/')
```

### Cachy.key
Use to cache e.g. Erb output

```Erb
<% cache Cachy.key(:a_key), :expires_in=>1.hour do %>
  More html ...
<% end %>
```

### Cachy.cache_store
No ActionController::Base.cache_store ?<br/>
Give me something that responds to read/write(Rails style) or []/store([Moneta](http://github.com/wycats/moneta/tree/master)) or get/set(Memcached)

```Ruby
Cachy.cache_store = some_cache
```

### Cachy.locales
No I18n.available_locales ?

```Ruby
Cachy.locales = [:de, :en, :fr]
```

### Memcache timeout protection
If Memcache timeouts keep killing your pages -> [catch MemCache timeouts](http://github.com/grosser/cachy/blob/master/lib/cachy/memcache_timeout_protection)

TODO
====
 - optionally store dependent keys (:keys=>xxx), so that they can be setup up once and do not need to be remembered

Authors
=======

###Contributors
 - [mindreframer](http://www.simplewebapp.de/roman)

[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/cachy.png)](https://travis-ci.org/grosser/cachy)

