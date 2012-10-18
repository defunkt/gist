describe '...' do
  before do
    @saved_env = ENV['HTTP_PROXY']
  end

  after do
    ENV['HTTP_PROXY'] = @saved_env
  end

  it "should be Net::HTTP when $HTTP_PROXY wasn't set" do
    ENV['HTTP_PROXY'] = ''
    Jist.http_connection().should be_an_instance_of(Net::HTTP)
  end

  it "should be Net::HTTP::Proxy when $HTTP_PROXY was set" do
    ENV['HTTP_PROXY'] = 'http://proxy.example.com:8080'
    Jist.http_connection().should_not be_an_instance_of(Net::HTTP)
  end
end
