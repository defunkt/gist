describe '...' do
  before do
    stub_request(:post, /api\.github.com\/gists\?access_token=.*/).to_return(:body => '{"html_url": "http://github.com/"}')
    stub_request(:post, "http://git.io/").to_return(:status => 201, :headers => { 'Location' => 'http://git.io/XXXXXX' })
  end

  it "should return a shortened version of the URL" do
    Gist.gist("Test gist", :output => :short_url).should == "http://git.io/XXXXXX"
  end
end

