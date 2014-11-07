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

    its(:xdg_path) { should be_a_pathname_for File.expand_path "~/.cache/gist/auth_token" }
    its(:legacy_path) { should be_a_pathname_for File.expand_path "~/.gist" }
    its(:github_url_suffix) { should == "" }
  end

  context "with custom GITHUB_URL" do
    before do ENV[Gist::URL_ENV_NAME] = github_url end
    let(:github_url) { "gh.custom.org" }

    its(:xdg_path) { should be_a_pathname_for File.expand_path "~/.cache/gist/auth_token.#{github_url}" }
    its(:legacy_path) { should be_a_pathname_for File.expand_path "~/.gist.#{github_url}" }
    its(:github_url_suffix) { should == ".#{github_url}" }
  end

  describe "auth token file location" do
    before do
      subject.xdg_path.stub(:exist?).and_return(xdg_tokens_exist)
      subject.legacy_path.stub(:exist?).and_return(legacy_tokens_exist)
    end

    context "when XDG_CACHE_HOME/gist/auth_token* exist" do
      let(:xdg_tokens_exist) { true }
      let(:legacy_tokens_exist) { "doesn't matter" }

      it { should be_xdg }
      its(:pathname) { should be_a_pathname_for subject.xdg_path }
    end

    context "when XDG_CACHE_HOME/gist/auth_token* don't exist" do
      let(:xdg_tokens_exist) { false }

      context "when ~/.gist* exists" do
        let(:legacy_tokens_exist) { true }

        it { should_not be_xdg }
        its(:pathname) { should be_a_pathname_for subject.legacy_path }
      end

      context "when ~/.gist* don't exist" do
        let(:legacy_tokens_exist) { false }

        it { should be_xdg }
        its(:pathname) { should be_a_pathname_for subject.xdg_path }
      end
    end

  end
end

describe Gist::AuthTokenPathname do
  before do
    stub_const("Gist::URL_ENV_NAME", "STUBBED_GITHUB_URL")
  end

  subject { Gist::AuthTokenPathname.new pathname }
  let(:pathname) { "/.gist" }

  its(:to_pathname) { should be_a Pathname }

  describe "#exist?" do
    before do Dir.should_receive(:glob).with(pathname + "*").and_return(globbed_files) end

    context "with any matching token files" do
      let(:globbed_files) { [double] }
      it { should exist }
    end

    context "without any matching token files" do
      let(:globbed_files) { [] }
      it { should_not exist }
    end
  end

  context "with default GITHUB_URL" do
    before do ENV.delete Gist::URL_ENV_NAME end

    its(:to_s) { should == File.expand_path(pathname) }
    its(:to_pathname) { should be_a_pathname_for pathname }
    its(:github_url_suffix) { should == "" }
  end

  context "with custom GITHUB_URL" do
    before do ENV[Gist::URL_ENV_NAME] = github_url end
    let(:github_url) { "gh.custom.org" }
    let(:github_url_suffix) { "." + github_url }

    its(:to_s) { should == File.expand_path(pathname+github_url_suffix) }
    its(:to_pathname) { should be_a_pathname_for pathname+github_url_suffix }
    its(:github_url_suffix) { should == github_url_suffix }
  end

end
