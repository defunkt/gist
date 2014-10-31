require_relative '../lib/auth_token_file'

describe Gist::AuthTokenFile do
  before(:context) { Gist::URL_ENV_NAME = "GITHUB_URL" }

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
    before { ENV[Gist::URL_ENV_NAME] = github_url }

    describe "#filename" do
      let(:filename) { File.expand_path "~/.gist" }

      it "is stored in $HOME" do
        subject.filename.should eq "#{filename}.#{github_url}"
      end
    end

  end

end
