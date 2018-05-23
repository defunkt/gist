describe '...' do
  before do
    stub_request(:post, /api\.github.com\/gists/).to_return(:body => '{"html_url": "http://github.com/"}')
  end

  it "should return a shortened version of the URL when response is 200" do
    stub_request(:post, "https://git.io/create").to_return(:status => 200, :body => 'XXXXXX')
    Gist.gist("Test gist", :output => :short_url, anonymous: false).should == "https://git.io/XXXXXX"
  end

  it "should return a shortened version of the URL when response is 201" do
    stub_request(:post, "https://git.io/create").to_return(:status => 201, :headers => { 'Location' => 'https://git.io/XXXXXX' })
    Gist.gist("Test gist", :output => :short_url, anonymous: false).should == "https://git.io/XXXXXX"
  end

  it 'should raise an error when trying to get short urls without being logged in' do
    error_msg = 'Anonymous gists are no longer supported. Please log in with `gist --login`. ' \
      '(Github now requires credentials to gist https://bit.ly/2GBBxKw)'

    expect do
      Gist.gist("Test gist", output: :short_url, anonymous: true)
    end.to raise_error(StandardError, error_msg)
  end
end
