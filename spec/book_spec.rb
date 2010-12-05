#require File.expand_path(File.dirname(__FILE__) + '/../lib/boot')
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Book do
  before(:each) do
  end

  it "should init with basic data" do
    book = Book.new "Title", "Joe", Date.new(2010, 5)
    book.title.should == "Title"
    book.creator.should == "Joe"
    book.pub_date.to_s.should == "2010-05-01"
    book.pub_year.should == 2010
    book.cc_url.should == "http://creativecommons.org/licenses/by-nc-nd/3.0/"
    the_id = book.book_id
    the_id.should =~ /^urn:uuid:.+/
    book.book_id.should == the_id
  end

  it "should use an isbn if one is given" do
    book = Book.new "Title 2", "Jack", Date.new(2009), "123456789X"
    book.book_id.should == "123456789X"
  end
end

