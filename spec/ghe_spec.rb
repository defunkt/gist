describe '...' do

  MOCK_GHE_HOST     = 'ghe.example.com'
  MOCK_GHE_PROTOCOL = 'http'
  MOCK_USER         = 'foo'
  MOCK_PASSWORD     = 'bar'

  MOCK_AUTHZ_GHE_URL    = "#{MOCK_GHE_PROTOCOL}://#{MOCK_USER}:#{MOCK_PASSWORD}@#{MOCK_GHE_HOST}/api/v3/"
  MOCK_GHE_URL          = "#{MOCK_GHE_PROTOCOL}://#{MOCK_GHE_HOST}/api/v3/"
  MOCK_AUTHZ_GITHUB_URL = "https://#{MOCK_USER}:#{MOCK_PASSWORD}@api.github.com/"
  MOCK_GITHUB_URL       = "https://api.github.com/"

  before do
    @saved_env = ENV[Jist::URL_ENV_NAME]

    # stub requests for /gists
    stub_request(:post, /#{MOCK_GHE_URL}gists/).to_return(:body => %[{"html_url": "http://#{MOCK_GHE_HOST}"}])
    stub_request(:post, /#{MOCK_GITHUB_URL}gists/).to_return(:body => '{"html_url": "http://github.com/"}')

    # stub requests for /authorizations
    stub_request(:post, /#{MOCK_AUTHZ_GHE_URL}authorizations/).
      to_return(:status => 201, :body => '{"token": "asdf"}')
    stub_request(:post, /#{MOCK_AUTHZ_GITHUB_URL}authorizations/).
      to_return(:status => 201, :body => '{"token": "asdf"}')
  end

  after do
    ENV[Jist::URL_ENV_NAME] = @saved_env
  end

  describe :login! do
    before do
      @saved_stdin = $stdin

      # stdin emulation
      $stdin = StringIO.new "#{MOCK_USER}\n#{MOCK_PASSWORD}\n"

      # intercept for updating ~/.jist
      File.stub(:open)
    end

    after do
      $stdin = @saved_stdin
    end

    it "should access to api.github.com when $#{Jist::URL_ENV_NAME} wasn't set" do
      ENV.delete Jist::URL_ENV_NAME

      Jist.login!

      assert_requested(:post, /#{MOCK_AUTHZ_GITHUB_URL}authorizations/)
    end

    it "should access to #{MOCK_GHE_HOST} when $#{Jist::URL_ENV_NAME} was set" do
      ENV[Jist::URL_ENV_NAME] = MOCK_GHE_URL

      Jist.login!

      assert_requested(:post, /#{MOCK_AUTHZ_GHE_URL}authorizations/)
    end
  end

  describe :gist do
    it "should access to api.github.com when $#{Jist::URL_ENV_NAME} wasn't set" do
      ENV.delete Jist::URL_ENV_NAME

      Jist.gist "test gist"

      assert_requested(:post, /#{MOCK_GITHUB_URL}gists/)
    end

    it "should access to #{MOCK_GHE_HOST} when $#{Jist::URL_ENV_NAME} was set" do
      ENV[Jist::URL_ENV_NAME] = MOCK_GHE_URL

      Jist.gist "test gist"

      assert_requested(:post, /#{MOCK_GHE_URL}gists/)
    end
  end
end
