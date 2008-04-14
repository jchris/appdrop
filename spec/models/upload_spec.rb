require File.dirname(__FILE__) + '/../spec_helper'

describe Upload do
  before(:each) do
    @upload = Upload.new
  end

  it "should be valid" do
    @upload.should be_valid
  end
end

# todo: make active record callbacks predictable :)
# describe Upload, "after create" do
#   fixtures :uploads
#   before(:each) do
#     @app = mock_model(App, :valid? => true)
#     @file = mock('file')
#     @file.stub!(:content_type).and_return('foo')
#     @file.stub!(:size).and_return(78)
#     @file.stub!(:original_filename).and_return('jammy.tar.gz')
#   end
#   it "should send it to the app" do
#     @app.should_receive(:update_code).with("#{RAILS_ROOT}/uploads/0000/0001/jammy.tar.gz")
#     @upload = Upload.new 'uploaded_data' => @file
#     @upload.app = @app
#     @upload.save!
#   end
# end