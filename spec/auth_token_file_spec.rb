describe Gist::AuthTokenFile do
  subject { Gist::AuthTokenFile }

  before(:each) do
    stub_const("Gist::URL_ENV_NAME", "STUBBED_GITHUB_URL")
  end

  describe "::filename" do
    let(:filename) { double() }

    context "with default GITHUB_URL" do
      it "is ~/.gist" do
        File.should_receive(:expand_path).with("~/.gist").and_return(filename)
        subject.filename.should be filename
      end
    end

    context "with custom GITHUB_URL" do
      before do
        ENV[Gist::URL_ENV_NAME] = github_url
      end
      let(:github_url) { "gh.custom.org" }

      it "is ~/.gist.{custom_github_url}" do
        File.should_receive(:expand_path).with("~/.gist.#{github_url}").and_return(filename)
        subject.filename.should be filename
      end
    end

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
      subject.stub(:filename) { filename }
    end

    it "writes token to file" do
      File.should_receive(:open).with(filename, 'w', 0600).and_yield(token_file)
      token_file.should_receive(:write).with(token)
      subject.write(token)
    end
  end
end
