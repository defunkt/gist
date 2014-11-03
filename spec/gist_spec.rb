describe Gist do

  describe "should_be_public?" do
    it "should return false if -p is specified" do
      Gist.should_be_public?(:private => true).should be_falsy
    end

    it "should return false if legacy_private_gister?" do
      Gist.should_receive(:legacy_private_gister?).and_return(true)
      Gist.should_be_public?.should be_falsy
    end

    it "should return true if --no-private is specified" do
      Gist.stub(:legacy_private_gister?).and_return(true)
      Gist.should_be_public?(:private => false).should be_truthy
    end

    it "should return true by default" do
      Gist.should_be_public?.should be_truthy
    end
  end

end
