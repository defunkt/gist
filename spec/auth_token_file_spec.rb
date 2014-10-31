require_relative '../lib/auth_token_file'

describe Gist::AuthTokenFile do
  before(:each) do
    stub_const("Gist::URL_ENV_NAME", "STUBBED_GITHUB_URL")
  end

  context "without custom GITHUB_URL" do
    let(:expected_filename) { File.expand_path "~/.gist" }

    describe "#filename" do
      it "is stored in $HOME" do
        subject.filename.should eq expected_filename
      end
    end

  end

  context "with custom GITHUB_URL" do
    let(:github_url) { "gh.custom.org" }
    let(:expected_filename) { File.expand_path "~/.gist.#{github_url}" }

    before do
      ENV[Gist::URL_ENV_NAME] = github_url
    end

    describe "#filename" do
      it "is stored in $HOME" do
        subject.filename.should eq expected_filename
      end
    end

  end

end
