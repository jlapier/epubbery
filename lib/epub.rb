# EpubSetup
# making directories and moving files and whatnot
class Epub
  class << self
    # kind of an orphaned method that just reads in chapters from text files and returns chapter objects
    def read_chapters(file_glob)
      file_glob = File.expand_path(file_glob)
      puts "Reading files: #{file_glob} (#{Dir[file_glob].size} files found)"
      chapters = []

      Dir[file_glob].each do |txtfile|
        chapter = nil
        File.open(txtfile) do |f|
          chapter = Chapter.new(f.readlines)
          chapter.file_name = "#{File.basename(txtfile, '.txt')}.html"
        end
        chapters << chapter if chapter
      end

      # returns chapters as an array sorted by name
      chapters.sort_by { |c| [c.number || 0, c.name || '', c.file_name] }
    end
  end

  def make_skeleton(base_dir, epub_folder, default_template = 'chapter')
    @epub_folder = epub_folder
    @source_templates_dir = File.join(base_dir, 'templates')
    @target_meta_dir = File.join(@epub_folder, 'META-INF')
    @target_oebps_dir = File.join(@epub_folder, 'OEBPS')

    FileUtils.rm_rf @epub_folder if File.exists?(@epub_folder)
    FileUtils.mkdir_p @epub_folder
    FileUtils.mkdir_p @target_meta_dir
    FileUtils.mkdir_p @target_oebps_dir

    FileUtils.cp File.join(@source_templates_dir, 'mimetype'), @epub_folder
    FileUtils.cp File.join(@source_templates_dir, 'META-INF', 'container.xml'), @target_meta_dir

    # TODO - somehow detect these "asset" folders and files - 
    # for now they are these defaults: css, images, fonts
    FileUtils.cp Dir[File.join(@source_templates_dir, 'OEBPS', '*.css')], @target_oebps_dir
    FileUtils.cp_r File.join(@source_templates_dir, 'OEBPS', 'images'), @target_oebps_dir
    FileUtils.cp_r File.join(@source_templates_dir, 'OEBPS', 'fonts'), @target_oebps_dir

    # liquid templates for rest of files
    @default_liq_template = Liquid::Template.parse(File.read(File.join(@source_templates_dir, 'OEBPS', "#{default_template.gsub(' ', '_')}.html.liquid"    )))
    @content_liq_template = Liquid::Template.parse(File.read(File.join(@source_templates_dir, 'OEBPS', 'content.opf.liquid'     )))
    @title_liq_template   = Liquid::Template.parse(File.read(File.join(@source_templates_dir, 'OEBPS', 'title.html.liquid'      )))
    @toc_liq_template     = Liquid::Template.parse(File.read(File.join(@source_templates_dir, 'OEBPS', 'toc.ncx.liquid'         )))
    @eob_liq_template     = Liquid::Template.parse(File.read(File.join(@source_templates_dir, 'OEBPS', 'end_of_book.html.liquid')))
  end

  def write_templates(book)
    book.chapters.each do |chapter|
      template = @default_liq_template
      if chapter.template
        template = Liquid::Template.parse(File.read(File.join(@source_templates_dir, 'OEBPS', "#{chapter.template.gsub(' ', '_')}.html.liquid"    )))
      end
      html_output = template.render 'chapter' => chapter
      puts "Writing: #{@epub_folder}/OEBPS/#{chapter.file_name}"
      File.open(File.join(@target_oebps_dir, chapter.file_name), "w") { |f| f.puts html_output }
    end

    puts "Writing: #{@epub_folder}/OEBPS/content.opf"
    File.open(File.join(@target_oebps_dir, 'content.opf'), "w") { |f| f.puts @content_liq_template.render('book' => book,
        'css_files'   => Dir[File.join(@source_templates_dir, 'OEBPS', '*.css')].map    { |f| File.basename(f) },
        'image_files' => Dir[File.join(@source_templates_dir, 'OEBPS', 'images', '*')].map { |f| File.basename(f) },
        'font_files'  => Dir[File.join(@source_templates_dir, 'OEBPS', 'fonts', '*')].map  { |f| File.basename(f) } ) }
    puts "Writing: #{@epub_folder}/OEBPS/title.html"
    File.open(File.join(@target_oebps_dir, 'title.html'), "w") { |f| f.puts @title_liq_template.render('book' => book) }
    puts "Writing: #{@epub_folder}/OEBPS/end_of_book.html"
    File.open(File.join(@target_oebps_dir, 'end_of_book.html'), "w") { |f| f.puts @eob_liq_template.render('book' => book) }
    puts "Writing: #{@epub_folder}/OEBPS/toc.ncx"
    File.open(File.join(@target_oebps_dir, 'toc.ncx'), "w") { |f| f.puts @toc_liq_template.render('book' => book) }
  end
end

