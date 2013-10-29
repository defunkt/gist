describe '...' do
  before do
    stub_request(:post, /api\.github.com\/gists/).to_return(:body => '{"html_url": "https://gist.github.com/XXXXXX"}')
    stub_request(:get, "https://gist.github.com/XXXXXX").to_return(:status => 304, :headers => { 'Location' => 'https://gist.github.com/anonymous/XXXXXX' })
    stub_request(:get, "https://gist.github.com/anonymous/XXXXXX").to_return(:status => 200)
  end

  it "should return the raw file url" do
    Gist.gist("Test gist", :output => :raw_url, :anonymous => true).should == "https://gist.github.com/anonymous/XXXXXX/raw"
  end
end

