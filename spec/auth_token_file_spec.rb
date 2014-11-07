describe Gist::AuthTokenFile do
  before(:each) do
    stub_const("Gist::URL_ENV_NAME", "STUBBED_GITHUB_URL")
  end

  describe "#read" do
    let(:token) { "auth_token" }
    let(:pathname) { double }

    before do subject.stub(:pathname).and_return(pathname) end

    it "reads file contents" do
      pathname.should_receive(:read).and_return(token)
      subject.read.should eq token
    end

    it "chomps file contents" do
      pathname.should_receive(:read).and_return(token + "\n")
      subject.read.should eq token
    end
  end

  describe "#write" do
    let(:token) { double }
    let(:pathname) { double }
    let(:token_file) { double }

    before do subject.stub(:pathname).and_return(pathname) end

    it "writes token to file" do
      pathname.should_receive(:open).with('w', 0600).and_yield(token_file)
      token_file.should_receive(:write).with(token)
      subject.write(token)
    end
  end

  context "with default GITHUB_URL" do
    before do ENV.delete Gist::URL_ENV_NAME end

    its(:xdg_path) { should be_a_pathname_for "~/.cache/gist/auth_token" }
    its(:legacy_path) { should be_a_pathname_for "~/.gist" }
    its(:github_url_suffix) { should == "" }
  end

  context "with custom GITHUB_URL" do
    before do ENV[Gist::URL_ENV_NAME] = github_url end
    let(:github_url) { "gh.custom.org" }

    its(:xdg_path) { should be_a_pathname_for "~/.cache/gist/auth_token.#{github_url}" }
    its(:legacy_path) { should be_a_pathname_for "~/.gist.#{github_url}" }
    its(:github_url_suffix) { should == ".#{github_url}" }
  end

  describe "auth token file location" do
    let(:xdg_path) { double }
    let(:legacy_path) { double }
    before do
      subject.stub(:xdg_path).and_return(xdg_path)
      subject.stub(:legacy_path).and_return(legacy_path)
    end

    context "when XDG_CACHE_HOME/gist/auth_token exists" do
      before do xdg_path.stub(:exist?).and_return(true) end

      it { should be_xdg }
      its(:pathname) { should == xdg_path }
    end

    context "when XDG_CACHE_HOME/gist/auth_token doesn't exit" do
      before do xdg_path.stub(:exist?).and_return(false) end

      context "when ~/.gist exists" do
        before do legacy_path.stub(:exist?).and_return(true) end

        it { should_not be_xdg }
        its(:pathname) { should == legacy_path }
      end

      context "when ~/.gist doesn't exist" do
        before do legacy_path.stub(:exist?).and_return(false) end

        it { should be_xdg }
        its(:pathname) { should == xdg_path }
      end
    end

  end
end

describe Gist::AuthTokenPathname do
  subject { Gist::AuthTokenPathname.new pathname }

  describe "#exist?" do
    let(:pathname) { "~/.gist" }

    before do
      Dir.should_receive(:glob).with(File.expand_path(pathname) + "*").and_return(globbed_files)
    end

    context "with any matching token files" do
      let(:globbed_files) { [double] }
      it { should exist }
    end

    context "without any matching token files" do
      let(:globbed_files) { [] }
      it { should_not exist }
    end
  end
end
