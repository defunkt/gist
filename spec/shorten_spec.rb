describe '...' do
  before do
    stub_request(:post, /api\.github.com\/gists/).to_return(:body => '{"html_url": "http://github.com/"}')
  end

  it "should return a shortened version of the URL when response is 200" do
    stub_request(:post, "https://git.io/create").to_return(:status => 200, :body => 'XXXXXX')
    Gist.gist("Test gist", :output => :short_url, :anonymous => true).should == "https://git.io/XXXXXX"
  end

  it "should return a shortened version of the URL when response is 201" do
    stub_request(:post, "https://git.io/create").to_return(:status => 201, :headers => { 'Location' => 'https://git.io/XXXXXX' })
    Gist.gist("Test gist", :output => :short_url, :anonymous => true).should == "https://git.io/XXXXXX"
  end
end
