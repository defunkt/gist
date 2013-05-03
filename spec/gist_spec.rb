describe Gist do

  describe "should_be_public?" do
    it "should return false if -p is specified" do
      Gist.should_be_public?(private: true).should be_false
    end

    it "should return false if legacy_private_gister?" do
      Gist.should_receive(:legacy_private_gister?).and_return(true)
      Gist.should_be_public?.should be_false
    end

    it "should return true by default" do
      Gist.should_be_public?.should be_true
    end
  end

end
