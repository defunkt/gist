require_relative '../lib/auth_token_file'

describe Gist::AuthTokenFile do
  before(:each) do
    stub_const("Gist::URL_ENV_NAME", "STUBBED_GITHUB_URL")
  end

  context "without custom GITHUB_URL" do
    describe "#filename" do
      let(:filename) { File.expand_path "~/.gist" }

      it "is stored in $HOME" do
        subject.filename.should eq filename
      end
    end

  end

  context "with custom GITHUB_URL" do
    let(:github_url) { "gh.custom.org" }
    before do
      ENV[Gist::URL_ENV_NAME] = github_url
    end

    describe "#filename" do
      let(:filename) { File.expand_path "~/.gist" }

      it "is stored in $HOME" do
        subject.filename.should eq "#{filename}.#{github_url}"
      end
    end

  end

end
