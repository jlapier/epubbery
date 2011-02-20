#!/usr/bin/ruby

@base_dir = File.expand_path(File.dirname(__FILE__) + '/..')

$: << File.join(@base_dir, 'lib')

require File.join(@base_dir, 'lib', 'text_to_epub')

include EpubSetup

@config = YAML::load(File.read('config.yml'))

@epub_folder = File.join(@base_dir, @config[:temp_epub_folder])

make_skeleton @base_dir, @epub_folder

@book = Book.new @config[:book_title], @config[:author]
@book.chapters = EpubSetup::read_chapters(@config[:chapter_glob])

write_templates(@book)

# TODO: use rubyzip or zipruby or something - they all seem to be a PITA compared to unix zip

FileUtils.cd @epub_folder
FileUtils.rm @config[:file_name] if File.exists?(@config[:file_name])

puts "\nGenerating #{@epub_folder}/#{@config[:file_name]}"

system "zip -0Xq #{@config[:file_name]} mimetype"
system "zip -Xr9Dq #{@config[:file_name]} *"

puts "\nRunning epubcheck..."
system "java -jar #{@config[:epubcheck]} #{@config[:file_name]}"


puts "\nnext convert to pdf for POD:"
puts "\nebook-convert #{@epub_folder}/#{@config[:file_name]} .pdf --custom-size=5x8 --base-font-size=12 --margin-top=54 --margin-left=54 --margin-bottom=54 --margin-right=54"

puts "\n -- or use wkhtmltopdf:"
puts "\nwkhtmltopdf --page-width 5in --page-height 8in -L 0.5in -R 0.5in -B 0.5in -T 0.25in --footer-center '[page]' --footer-spacing 2 --print-media-type --footer-font-name TexGyreTermes --footer-font-size 9 #{@epub_folder}/OEBPS/*.html mybook1.pdf"
