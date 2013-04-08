describe '...' do

  MOCK_GHE_HOST = 'ghe.example.com'
  MOCK_USER = 'foo'
  MOCK_PASSWORD = 'bar'
  MOCK_AUTHZ_GHE_URL = "http://#{MOCK_USER}:#{MOCK_PASSWORD}@#{MOCK_GHE_HOST}/"
  MOCK_GHE_URL = "http://#{MOCK_GHE_HOST}/"

  before do
    @saved_env = ENV['GHE_URL']

    # stub requests for /gists
    stub_request(:post, /^#{MOCK_GHE_URL}api\/v3\/gists/).to_return(:body => %[{"html_url": "#{MOCK_GHE_URL}"}])
    stub_request(:post, /^https:\/\/api.github.com\/gists/).to_return(:body => '{"html_url": "http://github.com/"}')

    # stub requests for /authorizations
    stub_request(:post, /^#{MOCK_AUTHZ_GHE_URL}api\/v3\/authorizations/).
      to_return(:status => 201, :body => '{"token": "asdf"}')
    stub_request(:post, /^https:\/\/#{MOCK_USER}:#{MOCK_PASSWORD}@api.github.com\/authorizations/).
      to_return(:status => 201, :body => '{"token": "asdf"}')
  end

  after do
    ENV['GHE_URL'] = @saved_env
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

    it "should access to api.github.com when $GHE_URL wasn't set" do
      ENV.delete 'GHE_URL'
      Jist.login!
      assert_requested(:post, /api.github.com/)
    end

    it "should access to #{MOCK_GHE_HOST} when $GHE_URL was set" do
      ENV['GHE_URL'] = MOCK_GHE_URL
      Jist.login!
      assert_requested(:post, /#{MOCK_GHE_HOST}/)
    end
  end

  describe :gist do
    it "should access to api.github.com when $GHE_URL wasn't set" do
      ENV.delete 'GHE_URL'
      Jist.gist "test gist"
      assert_requested(:post, /api.github.com/)
    end

    it "should access to #{MOCK_GHE_HOST} when $GHE_URL was set" do
      ENV['GHE_URL'] = MOCK_GHE_URL
      Jist.gist "test gist"
      assert_requested(:post, /#{MOCK_GHE_HOST}/)
    end
  end
end
