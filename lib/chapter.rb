# Chapter 
# contains name, content (text-only)
# generates html
# file_name should reference html file after it is written
class Chapter
  attr_accessor :number, :name, :subhead, :file_name, :content
  liquid_methods :number, :name, :subhead, :file_name, :word_count, :html, :chapter_id,
    :number_as_word, :number_or_name, :name_or_number

  def initialize(lines)
    meta = true
    while meta and line = lines.shift do
      line.strip!
      if line =~ /^Chapter:/
        meta_num = line.scan(/^Chapter:\s*(\d+)/).flatten.first
        self.number = meta_num.strip.to_i if meta_num
      elsif line =~ /^Name:/
        meta_name = line.scan(/^Name:\s*(.+)/).flatten.first
        self.name = meta_name.strip if meta_name
      elsif line =~ /^Subhead:/
        meta_sub = line.scan(/^Subhead:\s*(.+)/).flatten.first
        self.subhead = meta_sub.strip if meta_sub
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

  # if there is a number, give us that written out as words; otherwise give the chapter name
  def number_or_name
    if number
      "Chapter #{number_as_word}"
    else
      name
    end
  end
  
  # if there is a name, give us that; otherwise give the number written out as words
  def name_or_number
    if name and !name.empty?
      name
    elsif number
      "Chapter #{number_as_word}"
    else
      nil
    end
  end
end
