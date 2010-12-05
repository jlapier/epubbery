# Book: contains info like title and creator
# also contains an array of chapters (Chapter class)
class Book
  attr_accessor :title, :creator, :chapters, :pub_date, :pub_year, :isbn
  liquid_methods :title, :creator, :chapters, :pub_date, :pub_year, :book_id, :cc_url

  def initialize(title, creator, pub_date = Date.today, isbn = nil)
    self.title = title
    self.creator = creator
    self.pub_date = pub_date
    self.isbn = isbn
  end

  def book_id
    @book_id ||= (isbn || "urn:uuid:#{UUID.new.generate}")
  end

  def pub_year
    pub_date.year
  end

  def cc_url
    # attribution only, free to distribute, modify, or use commercially:
    # "http://creativecommons.org/licenses/by/3.0/"

    # free to share with attribution, non-commercial, no derivatives
    "http://creativecommons.org/licenses/by-nc-nd/3.0/"
  end
end

