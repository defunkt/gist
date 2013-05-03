describe '...' do
  before do
    @saved_path = ENV['PATH']
    @bobo_url = 'http://example.com'
  end

  after do
    ENV['PATH'] = @saved_path
  end

  def ask_for_copy
    Gist.on_success({'html_url' => @bobo_url}.to_json, :copy => true, :output => :html_url)
  end
  def gist_but_dont_ask_for_copy
    Gist.on_success({'html_url' => 'http://example.com/'}.to_json, :output => :html_url)
  end

  it 'should try to copy the url when the clipboard option is passed' do
    Gist.should_receive(:copy).with(@bobo_url)
    ask_for_copy
  end

  it 'should try to copy the embed url when the clipboard-js option is passed' do
    js_link = %Q{<script src="#{@bobo_url}.js"></script>}
    Gist.should_receive(:copy).with(js_link)
    Gist.on_success({'html_url' => @bobo_url}.to_json, :copy => true, :output => :javascript)
  end

  it "should not copy when not asked to" do
    Gist.should_not_receive(:copy).with(@bobo_url)
    gist_but_dont_ask_for_copy
  end

  it "should raise an error if no copying mechanisms are available" do
    ENV['PATH'] = ''
    lambda{
      ask_for_copy
    }.should raise_error(/Could not find copy command.*http/m)
  end
end
