describe Gist::XDG do
  subject { Gist::XDG }

  context "with $XDG_CACHE_HOME set" do
    before do
      ENV['XDG_CACHE_HOME'] = "some/cache/path"
    end

    its(:cache_home) { should == "some/cache/path" }
  end

  context "with $XDG_CACHE_HOME unset" do
    before do
      ENV.delete 'XDG_CACHE_HOME'
    end

    its(:cache_home) { should == "~/.cache" }
  end

  describe "::cache" do
    before do
      ENV['XDG_CACHE_HOME'] = "/cache_home"
    end

    it "should expand given path relative to CACHE_HOME" do
      subject.cache("mydir").should == "/cache_home/mydir"
    end
  end
end
