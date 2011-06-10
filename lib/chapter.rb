# Chapter 
# contains name, content (text-only)
# generates html
# file_name should reference html file after it is written
class Chapter
  attr_accessor :number, :meta, :file_name, :content
  liquid_methods :number, :meta, :file_name, :word_count, :html, :chapter_id,
    :number_as_word, :number_or_name, :name_or_number

  def initialize(lines)
    self.meta = {}
    meta = true
    while meta and line = lines.shift do
      line.strip!
      matches = line.match /^(.+):\s+(.+)/
      if matches
        if matches[1] =~ /(Chapter|Number|Position)/i and matches[2] =~ /\d+/ and number.nil?
          self.number = matches[2].strip.to_i
        end
        self.meta[matches[1].downcase] = matches[2]
      else
        lines = [line] + lines if line
        meta = false 
      end
    end

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
    meta['name'] || ""
  end

  def template
    meta['template'] || nil
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
end
