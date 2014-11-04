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
end
