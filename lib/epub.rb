# EpubSetup
# making directories and moving files and whatnot
class Epub
  class << self
    # kind of an orphaned method that just reads in chapters from text files 
    # and returns chapter objects
    def read_chapters(file_glob)
      file_glob = File.expand_path(file_glob)
      puts "Reading files: #{file_glob} (#{Dir[file_glob].size} files found)"
      chapters = []

      Dir[file_glob].each do |txtfile|
        chapter = nil
        File.open(txtfile) do |f|
          chapter = Chapter.new(f.readlines)
          chapter.file_name = "#{File.basename(txtfile, '.txt').gsub(/\W/,'_')}.html"
        end
        chapters << chapter if chapter
      end

      # returns chapters as an array sorted by number or file_name
      chapters.sort
    end
  end

  # only useful for setting up the generation of actual HTML files
  # not used in the current version of the gem (HTML is generated in memory, 
  # not written to files)
  def make_skeleton(base_dir, epub_folder, default_template = 'chapter')
    default_template ||= 'chapter'
    @epub_folder = epub_folder
    @source_templates_dir = File.join(base_dir, 'templates')
    @target_meta_dir = File.join(@epub_folder, 'META-INF')
    @target_oebps_dir = File.join(@epub_folder, 'OEBPS')

    FileUtils.rm_rf @epub_folder if File.exists?(@epub_folder)
    FileUtils.mkdir_p @epub_folder
    FileUtils.mkdir_p @target_meta_dir
    FileUtils.mkdir_p @target_oebps_dir

    FileUtils.cp File.join(@source_templates_dir, 'META-INF', 'container.xml'), 
      @target_meta_dir

    # TODO - somehow detect these "asset" folders and files - 
    # for now they are these defaults: css, images, fonts
    FileUtils.cp Dir[File.join(@source_templates_dir, 'OEBPS', '*.css')], 
      @target_oebps_dir
    FileUtils.cp_r File.join(@source_templates_dir, 'OEBPS', 'images'), 
      @target_oebps_dir
    FileUtils.cp_r File.join(@source_templates_dir, 'OEBPS', 'fonts'), 
      @target_oebps_dir

    load_file_templates(base_dir, default_template)
  end

  # load liquid templates from files in the templates directory
  def load_file_templates(base_dir, default_template = 'chapter')
    @source_templates_dir ||= File.join(base_dir, 'templates')

    # liquid templates for rest of files
    default = File.read(File.join(@source_templates_dir, 'OEBPS', 
              "#{default_template.gsub(' ', '_')}.html.liquid" ))
    content = File.read(File.join(@source_templates_dir, 'OEBPS', 
              'content.opf.liquid'))
    title = File.read(File.join(@source_templates_dir, 'OEBPS', 'title.html.liquid'))
    toc = File.read(File.join(@source_templates_dir, 'OEBPS', 'toc.ncx.liquid'))
    eob = File.read(File.join(@source_templates_dir, 'OEBPS', 
              'end_of_book.html.liquid'))

    load_custom_templates(default, content, title, toc, eob)
  end

  # load liquid templates, manually (provide String objects from memory or db)
  # default: default template for all chapters (html)
  # content: template for content.opf (xml)
  # title: title page (html)
  # toc: table of contents (for toc.ncx, xml)
  # eob: end of book page (html)
  def load_custom_templates(default, content, title, toc, eob)
    @default_liq_template = Liquid::Template.parse(default)
    @content_liq_template = Liquid::Template.parse(content)
    @title_liq_template   = Liquid::Template.parse(title)
    @toc_liq_template     = Liquid::Template.parse(toc)
    @eob_liq_template     = Liquid::Template.parse(eob)
  end

  # finds css, images, fonts in templates directory
  def find_asset_files
    @css_files = Dir[File.join(@source_templates_dir, 'OEBPS', '*.css')].
      map { |f| File.basename(f) }
    @image_files = Dir[File.join(@source_templates_dir, 'OEBPS', 'images', '*')].
      map { |f| File.basename(f) }
    @font_files = Dir[File.join(@source_templates_dir, 'OEBPS', 'fonts', '*')].
      map { |f| File.basename(f) }
  end

  # provide arrays of each asset type (directory path not necessary)
  def custom_asset_files(css_files, image_files, font_files)
    @css_files = css_files
    @image_files = image_files
    @font_files = font_files
  end

  # returns a hash where the keys are file paths and the values are rendered templates
  # provide extra templates in the form of a hash: 
  # { 'name' => 'liquid template string' }
  def render_templates(book, extra_templates = nil)
    unless extra_templates
      # scan the source folder for html liquid templates
      extra_templates = {}
      Dir[File.join(@source_templates_dir, 'OEBPS', '*.html.liquid')].each do |f|
        friendly_name = File.basename(f).gsub('_', ' ').gsub('.html.liquid', '')
        extra_templates[friendly_name] = File.read(f)
      end
    end

    rendered = {}
    find_asset_files unless @css_files

    book.chapters.each do |chapter|
      template = @default_liq_template
      # if this chapter has a specific template AND we can find it, use it
      if chapter.template and extra_templates[chapter.template.downcase]
        template = Liquid::Template.parse(extra_templates[chapter.template.downcase])
      end
      html_output = template.render 'chapter' => chapter
      puts "Rendering: OEBPS/#{chapter.file_name}"
      rendered[File.join('OEBPS', chapter.file_name)] = html_output
    end

    puts "Rendering: OEBPS/content.opf"
    # content.opf template needs to know location of asset files
    rendered[File.join('OEBPS', 'content.opf')] = @content_liq_template.render(
        'book' => book,
        'css_files'   => @css_files,
        'image_files' => @image_files,
        'font_files'  => @font_files )

    puts "Rendering: OEBPS/title.html"
    rendered[File.join('OEBPS', 'title.html')] = @title_liq_template.render(
        'book' => book)

    puts "Rendering: OEBPS/end_of_book.html"
    rendered[File.join('OEBPS', 'end_of_book.html')] = @eob_liq_template.render(
        'book' => book) 

    puts "Rendering: OEBPS/toc.ncx"
    rendered[File.join('OEBPS', 'toc.ncx')] = @toc_liq_template.render(
        'book' => book) 

    rendered
  end

  def write_templates(book)
    rendered_templates = render_templates(book)
    rendered_templates.each do |filepath, text|
      puts "Writing: #{@epub_folder}/#{filepath}"
      File.open(File.join(@epub_folder, filepath), "w") { |f| f.puts text }
    end
  end

  def create_zip(book, zipfile, asset_loc = nil, container_loc = nil)
    asset_loc ||= File.join(@source_templates_dir, 'OEBPS')
    container_loc ||= File.join(@source_templates_dir, 'META-INF', 'container.xml')
    rendered_templates = render_templates(book)

    Zip::Archive.open(zipfile) do |ar|
      ar.add_file 'META-INF/container.xml', container_loc
      @css_files.each do |f|
        ar.add_file("OEBPS/#{f}", File.join(asset_loc, f))
      end
      @image_files.each do |f|
        ar.add_file("OEBPS/images/#{f}", File.join(asset_loc, 'images', f))
      end
      @font_files.each do |f|
        ar.add_file("OEBPS/fonts/#{f}", File.join(asset_loc, 'fonts', f))
      end
      rendered_templates.each do |filepath, text|
        puts "Adding: #{filepath}"
        ar.add_buffer filepath, text
      end  
    end
  end
end

