require 'spec/spec_helper'

describe Cachy do
  before do
    CACHE.clear
  end
  
  describe :cache do
    it "caches" do
      Cachy.cache(:my_key){ "X" }.should == "X"
      Cachy.cache(:my_key){ "ABC" }.should == "X"
    end
    
    it "expires" do
      Cachy.cache(:his_key, :expires_in=> -100){ 'X' }.should == 'X'
      Cachy.cache(:his_key, :expires_in=> -100){ 'X' }.should == 'X'
    end
    
    it "sets cache to intermediate value while running expensive query" do
      Cachy.cache(:my_key, :while_running=>'A') do
        Cachy.cache(:my_key){ 'X' }.should == 'A'
      end
    end
  end

  describe :expire do
    it "expires the cache for all languages" do
      Cachy.cache(:another_key){ "X" }

      $LANGUAGES.each do |l|
        I18n.locale = l
        Cachy.cache(:my_key){ "X#{l}" }.should == "X#{l}"
        Cachy.cache(:my_key){ "YYY" }.should == "X#{l}"
      end

      Cachy.expire(:my_key)

      CACHE.keys.should include("another_key_v1_#{CACHE_VERSION}_de")
      CACHE.keys.detect{|k| k=~ /my_key/}.should == nil
    end
  end

  describe :key do
    it "caches on updated at timestamps for model" do
      user = Factory(:user)
      Cachy.key(:my_key, user).should == "my_key_User:#{user.id}:#{user.updated_at.to_i}_v1_#{CACHE_VERSION}_de"
    end

    it "sorts models by name" do
      user = Factory(:user)
      product = Factory(:product)
      Cachy.key(:a_key, product, user, product, :my_key).should =~ /my_key.*Product.*Product.*User/
    end

    it "does not sort non-models" do
      user = Factory(:user)
      Cachy.key(:my_key, 1, user, "abc").should =~ /^my_key_1_abc_User:\d+:\d+_v1_#{CACHE_VERSION}_de$/
    end

    it "adds current_language" do
      Cachy.key(:x).should == "x_v1_#{CACHE_VERSION}_de"
    end

    it "raises on unknown options" do
      lambda{Cachy.key(:x, :asdasd=>'asd')}.should raise_error
    end

    describe "with :keys" do
      it "is stable" do
        Cachy.key(:x, :keys=>'asd').should == Cachy.key(:x, :keys=>'asd')
      end

      it "changes when dependent key changes" do
        lambda{
          Cachy.increment_key('asd')
        }.should change{Cachy.key(:x, :keys=>'asd')}
      end

      it "is different for different keys" do
        Cachy.key(:x, :keys=>'xxx').should_not == Cachy.key(:x, :keys=>'yyy')
      end
    end

    describe 'with :without_locale' do
      it "is stable with same locale" do
        Cachy.key(:x, :without_locale=>true).should == Cachy.key(:x, :without_locale=>true)
      end

      it "is stable with different locales" do
        de_key = Cachy.key(:x, :without_locale=>true)
        I18n.with_locale 'en' do
          Cachy.key(:x, :without_locale=>true).should == de_key
        end
      end
    end
  end

  describe :key_versions do
    before do
      Cachy.key_versions = {}
      Cachy.key_versions.should == {}
    end

    it "adds a key when cache is called the first time" do
      Cachy.cache(:xxx){1}
      Cachy.key_versions[:xxx].should == 1
    end

    it "adds a string key as symbol" do
      Cachy.cache('yyy'){1}
      Cachy.key_versions[:yyy].should == 1
    end

    it "does not overwrite a key when it already exists" do
      Cachy.key_versions[:xxx] = 3
      Cachy.cache(:xxx){1}
      Cachy.cache(:xxx){1}
      Cachy.key_versions[:xxx].should == 3
    end

    it "reloads when keys have expired" do
      Cachy.send :class_variable_set, "@@key_versions", {:versions=>{:xx=>2}, :last_set=>1.minute.ago}
      CACHE['cachy_key_versions'] = {:xx=>1}
      Cachy.key_versions.should == {:xx=>1}
    end

    it "does not reload when keys have not expired" do
      Cachy.send :class_variable_set, "@@key_versions", {:versions=>{:xx=>2}, :last_set=>Time.now}
      CACHE['cachy_key_versions'] = {:xx=>1}
      Cachy.key_versions.should == {:xx=>2}
    end

    it "expires when key_versions is set" do
      Cachy.send :class_variable_set, "@@key_versions", {:versions=>{:xx=>2}, :last_set=>Time.now}
      Cachy.key_versions = {:xx=>1}
      Cachy.key_versions[:xx].should == 1
    end
  end
end