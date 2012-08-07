describe '...' do
  before do
    @saved_path = ENV['PATH']
    @bobo_url = 'http://example.com'
  end

  after do
    ENV['PATH'] = @saved_path
  end

  def ask_for_copy
    Jist.on_success({'html_url' => @bobo_url}.to_json, :copy => true )
  end
  def jist_but_dont_ask_for_copy
    Jist.on_success({'html_url' => 'http://example.com/'}.to_json)
  end

  it 'should try to copy the url when the clipboard option is passed' do
    Jist.should_receive(:copy).with(@bobo_url)
    ask_for_copy
  end

  it "should not copy when not asked to" do
    Jist.should_not_receive(:copy).with(@bobo_url)
    jist_but_dont_ask_for_copy
  end

  it "should raise an error if no copying mechanisms are available" do
    ENV['PATH'] = ''
    lambda{
      ask_for_copy
    }.should raise_error(/Could not find copy command/)
  end
end
