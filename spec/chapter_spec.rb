#require File.expand_path(File.dirname(__FILE__) + '/../lib/boot')
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Chapter do
  before(:each) do
    @lines_with_meta = <<-EOF
      Chapter: 13
      Name: This is a Chapter with Meta
      Subhead: Created: on November 20th

      "It all began a long time ago," he said.

      And he _told_ his tale.
    EOF
    @file_lines_with_meta = @lines_with_meta.split("\n")


    @lines_without_meta = <<-EOF
      "It all began a long time ago," he said.

      And he _told_ his tale.
    EOF

    @file_lines_without_meta = @lines_without_meta.split("\n")
  end

  it "should init with meta (file)" do
    chapter = Chapter.new(@file_lines_with_meta)
    chapter.number.should == 13
    chapter.name.should == "This is a Chapter with Meta"
    chapter.meta[:subhead].should == "Created: on November 20th"
    chapter.content.should include('began a long time')
    chapter.content.should include('his tale')
  end

  it "should init with meta (text)" do
    chapter = Chapter.new(@lines_with_meta)
    chapter.number.should == 13
    chapter.name.should == "This is a Chapter with Meta"
    chapter.meta[:subhead].should == "Created: on November 20th"
    chapter.content.should include('began a long time')
    chapter.content.should include('his tale')
  end

  it "should init with meta (file) and override with option" do
    chapter = Chapter.new(@file_lines_with_meta, :name => "New Name")
    chapter.number.should == 13
    chapter.name.should == "New Name"
    chapter.meta[:subhead].should == "Created: on November 20th"
    chapter.content.should include('began a long time')
    chapter.content.should include('his tale')
  end

  it "should init without meta" do
    chapter = Chapter.new(@file_lines_without_meta)
    chapter.number.should be(nil)
    chapter.name.should == ''
    chapter.number_or_name.should == ""
    chapter.name_or_number.should == ""
    chapter.meta[:subhead].should be(nil)
    chapter.content.should include('began a long time')
    chapter.content.should include('his tale')
  end

  it "should use redcloth to process text" do
    chapter = Chapter.new(@file_lines_with_meta)
    chapter.html.should include('<p>')
    chapter.content.should include('_told_ his tale')
    chapter.html.should include('<em>told</em> his tale')
  end
  
  it "should have some name and number helper methods" do
    chapter = Chapter.new(@file_lines_with_meta)
    chapter.file_name = "chap_13"
    chapter.number_or_name.should == "Chapter Thirteen"
    chapter.name_or_number.should == "This is a Chapter with Meta"
    chapter.name_or_file.should == "This is a Chapter with Meta"
  end

  it "should have some name and number helper methods without meta" do
    chapter = Chapter.new(@file_lines_without_meta)
    chapter.file_name = "chap_13"
    chapter.number_or_name.should == ""
    chapter.name_or_number.should == ""
    chapter.name_or_file.should == "chap_13"
  end

  it "should sort like a human" do
    s10 = Chapter.new("Name: Scene 10\n")
    s2 = Chapter.new("Name: Scene_2\n")
    c5 = Chapter.new("Chapter: 5\nName: Specified chapter numbers sort first\n")
    s2a = Chapter.new("Name: Scene 2a\n")
    s2b = Chapter.new("Name: Scene 2b\n")
    s8 = Chapter.new("Name: Scene 8 - some unnecessary stuff at end of name\n")
    s7 = Chapter.new("Name: Scene_ 7-some unnecessary ztuff\n")
    c4 = Chapter.new("Chapter: 4\nName: Specified chapter numbers sort first\n")
    [s10, s2].sort.should == [s2, s10]
    [s10, s2, s8].sort.should == [s2, s8, s10]
    [c5, c4].sort.should == [c4, c5]
    [s10, s2, c4].sort.should == [c4, s2, s10]
    [s2b, s2a].sort.should == [s2a, s2b]
    [s2a, s2].sort.should == [s2, s2a]
    [s10, s2, s2a].sort.should == [s2, s2a, s10]
    [s10, s2, c5, s8, s2a, s7, c4].sort.should == [c4, c5, s2, s2a, s7, s8, s10]
  end

  it "should count words" do
    chapter = Chapter.new(@file_lines_without_meta)
    chapter.word_count.should == 14
  end
end

