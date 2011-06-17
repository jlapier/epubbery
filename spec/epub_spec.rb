require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Epub do
  before(:all) do
    @epub = Epub.new
    @tmp_epub_folder = "test_epub_folder_safe_to_remove_will_be_deleted"
    @base_dir = File.expand_path(File.dirname(__FILE__) + "/..")
    @tmp_text_folder = "test_epub_folder_safe_to_remove_will_be_deleted2"
    FileUtils.rm_rf File.join(@base_dir, @tmp_text_folder) if File.exists?(File.join(@base_dir, @tmp_text_folder))
    FileUtils.mkdir File.join(@base_dir, @tmp_text_folder)
    FileUtils.cp File.join(@base_dir, 'templates', 'OEBPS', "chapter.html.liquid"),
        File.join(@base_dir, 'templates', 'OEBPS', 'delete_this_alternate.html.liquid')
    File.open(File.join(@base_dir, @tmp_text_folder, "1.txt"), "w") do |f|
        f.puts "Chapter: 1\n"
        f.puts "Blah blah blah.\n"
    end
    File.open(File.join(@base_dir, @tmp_text_folder, "2.txt"), "w") do |f|
        f.puts "Chapter: 2\n"
        f.puts "Template: delete this alternate\n"
        f.puts "Bork bork bork.\n"
    end
  end

  after(:all) do
    FileUtils.rm_rf File.join(@base_dir, @tmp_epub_folder)
    FileUtils.rm_rf File.join(@base_dir, @tmp_text_folder)
    FileUtils.rm File.join(@base_dir, 'templates', 'OEBPS', 'delete_this_alternate.html.liquid')
  end

  it "should make skeleton" do
    @epub.make_skeleton @base_dir, @tmp_epub_folder
    File.exists?(File.join(@tmp_epub_folder, 'META-INF')).should == true
    File.exists?(File.join(@tmp_epub_folder, 'META-INF', 'container.xml')).should == true
    File.exists?(File.join(@tmp_epub_folder, 'OEBPS')).should == true
    File.exists?(File.join(@tmp_epub_folder, 'OEBPS', 'stylesheet.css')).should == true
  end

  it "should read chapters from a glob file description" do
    chapters = Epub.read_chapters("#{File.join(@base_dir, @tmp_text_folder)}/*.txt")
    chapters.size.should == 2
    chapters.first.file_name.should == "1.html"
    chapters[1].file_name.should == "2.html"
  end

  it "should write tempates into the epub folder" do
    @epub.make_skeleton @base_dir, @tmp_epub_folder
    book = Book.new "Testy", "Jason", Date.new(2001)
    book.chapters = Epub.read_chapters("#{File.join(@base_dir, @tmp_text_folder)}/*.txt")
    @epub.write_templates book
    File.exists?(File.join(@tmp_epub_folder, 'OEBPS', 'title.html')).should == true
    File.exists?(File.join(@tmp_epub_folder, 'OEBPS', '1.html')).should == true
    File.exists?(File.join(@tmp_epub_folder, 'OEBPS', '2.html')).should == true
    File.exists?(File.join(@tmp_epub_folder, 'OEBPS', 'end_of_book.html')).should == true
  end

  it "should write tempates into the epub folder" do
    @epub.make_skeleton @base_dir, @tmp_epub_folder
    book = Book.new "Testy", "Jason", Date.new(2001)
    book.chapters = Epub.read_chapters("#{File.join(@base_dir, @tmp_text_folder)}/*.txt")
    @epub.write_templates book
    File.exists?(File.join(@tmp_epub_folder, 'OEBPS', 'title.html')).should == true
    File.exists?(File.join(@tmp_epub_folder, 'OEBPS', '1.html')).should == true
    File.exists?(File.join(@tmp_epub_folder, 'OEBPS', '2.html')).should == true
    File.exists?(File.join(@tmp_epub_folder, 'OEBPS', 'end_of_book.html')).should == true
  end
end
