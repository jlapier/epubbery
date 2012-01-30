# Chapter
#
# contains name, content (text-only), generates html
#
# file_name should reference html file to be written (inside epub archive)
class Chapter
  include Comparable

  attr_accessor :number, :meta, :file_name, :content
  liquid_methods :number, :meta, :file_name, :word_count, :html, :chapter_id,
    :name, :number_as_word, :number_or_name, :name_or_number

  # Chapter.new(lines, options) where lines is a string or an array of strings, 
  # options will override meta variables
  def initialize(lines, options = {})
    if lines.is_a?(String)
      lines = lines.split("\n")
    end
    self.meta = {}
    in_meta = true
    while in_meta and line = lines.shift do
      line.strip!
      matches = line.match /^([^:]+):\s+(.+)/
      if matches
        if matches[1] =~ /(Chapter|Number|Position)/i and matches[2] =~ /\d+/ and number.nil?
          self.number = matches[2].strip.to_i
        end
        self.meta[matches[1].downcase.to_sym] = matches[2]
      else
        lines = [line] + lines if line
        in_meta = false 
      end
    end
    self.meta.merge!(options)
    self.file_name = self.meta[:file_name]
    self.content = lines.join
  end

  def word_count
    @word_count ||= (name + content).gsub(/(_|\*|,|:)/, '').scan(/(\w|-|')+/).size
  end
  
  def html
    content.strip!
    @html ||= RedCloth.new(content).to_html
  end

  def chapter_id
    @book_id ||= file_name.gsub(/\W/,'_').gsub('.html', '')
  end

  def number_as_word
    number ? Linguistics::EN.numwords(number).capitalize : nil
  end

  def name
    meta[:name] || ""
  end

  def template
    meta[:template] || nil
  end

  # if there is a number, give us that written out as words; otherwise give the chapter name
  def number_or_name
    number ? "Chapter #{number_as_word}" : name
  end
  
  # if there is a name, give us that; otherwise give the number written out as words
  def name_or_number
    if !name.empty?
      name
    elsif number
      "Chapter #{number_as_word}"
    else
      ""
    end
  end

  def name_or_file
    if !name.empty?
      name
    else
      file_name || 'I_have_no_file_name'
    end
  end

  # we try to do a more human sort - so it's okay to mix words and letters in titles
  # we also ignore whitespace, underscores, and dashes - that should help with sorting 
  # when you only have filenames to work with
  def <=>(other)
    if number and other.number
      return number <=> other.number
    elsif number
      return -1
    elsif other.number
      return 1
    else
      name_or_file.gsub(/\s+|_|-/, '').split(/(\d+)/).map {|s| s =~ /\d+/ ? s.to_i : s } <=> 
        other.name_or_file.gsub(/\s+|_|-/, '').split(/(\d+)/).map {|s| s =~ /\d+/ ? s.to_i : s }
    end
  end

end
