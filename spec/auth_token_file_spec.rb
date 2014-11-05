describe Gist::AuthTokenFile do
  subject { Gist::AuthTokenFile }

  before(:each) do
    stub_const("Gist::URL_ENV_NAME", "STUBBED_GITHUB_URL")
    stub_const("Gist::XDG::CACHE_HOME_ENV_NAME", "STUBBED_XDG_CACHE_HOME")
  end

  describe "::read" do
    let(:token) { "auth_token" }

    it "reads file contents" do
      File.should_receive(:read).and_return(token)
      subject.read.should eq token
    end

    it "chomps file contents" do
      File.should_receive(:read).and_return(token + "\n")
      subject.read.should eq token
    end
  end

  describe "::write" do
    let(:token) { double() }
    let(:filename) { double() }
    let(:token_file) { double() }

    before do
      subject.stub(:pathname) { filename }
    end

    it "writes token to file" do
      File.should_receive(:open).with(filename, 'w', 0600).and_yield(token_file)
      token_file.should_receive(:write).with(token)
      subject.write(token)
    end
  end

  context "with default GITHUB_URL" do
    before do
      ENV.delete Gist::URL_ENV_NAME
      File.stub(:expand_path) {|f| f }
    end

    its(:xdg_path) { should == "~/.cache/gist/auth_token" }
    its(:legacy_path) { should == "~/.gist" }
    its(:github_url_suffix) { should == "" }
  end

  context "with custom GITHUB_URL" do
    before do
      ENV[Gist::URL_ENV_NAME] = github_url
      File.stub(:expand_path) {|f| f }
    end
    let(:github_url) { "gh.custom.org" }

    its(:xdg_path) { should == "~/.cache/gist/auth_token.#{github_url}" }
    its(:legacy_path) { should == "~/.gist.#{github_url}" }
    its(:github_url_suffix) { should == ".#{github_url}" }
  end

  context "when XDG_CACHE_HOME/gist/auth_token exists" do
    before do
      File.should_receive(:exist?).with(subject.xdg_path).and_return(true)
    end

    it { should be_xdg }
    its(:pathname) { should == subject.xdg_path }
  end

  context "when XDG_CACHE_HOME/gist/auth_token doesn't exit" do
    before do
      File.should_receive(:exist?).with(subject.xdg_path).and_return(false)
    end

    context "when ~/.gist exists" do
      before do
        File.should_receive(:exist?).with(subject.legacy_path).and_return(true)
      end

      it { should_not be_xdg }
      its(:pathname) { should == subject.legacy_path }
    end

    context "when ~/.gist doesn't exist" do
      before do
        File.should_receive(:exist?).with(subject.legacy_path).and_return(false)
      end

      it { should be_xdg }
      its(:pathname) { should == subject.xdg_path }
    end
  end

end
