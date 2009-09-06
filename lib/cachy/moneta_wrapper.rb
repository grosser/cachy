require 'cachy/wrapper'

# Wrapper for Moneta http://github.com/wycats/moneta/tree/master
class Cachy::MonetaWrapper < Cachy::Wrapper
  def write(key, result, options={})
    @wrapped.store(key, result, options)
  end
end