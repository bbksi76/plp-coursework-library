require 'singleton'

class Calendar
  include Singleton
  # ...
  def initialize
    @date = 0
  end

  def get_date
    @date
  end

  def advance
    @date += 1
  end

  def self.reset
    @singleton__instance__ = nil
  end
end

class Member
  def initialize(name, library)
    @name = name
    @library = library
    @books = []
    # or... @books   = Hash.new ??  Use a hash?
    # or... @book_set = Set.new ??  Use a set?
    # @@MAX_NUM_BOOKS = 3

    # @library_card = false ??  - why is this needed??
  end

  def get_name
    @name
  end

  def check_out(book)
    # if(@books.size()<3) ???
    @books.push(book)	# or... @books[book.id] = book
    # book.check_out(@library.calendar.get_date() + 7)
  end

  # The spec states this method _should_ be called "return"
  # My understanding of this statement is that this isn't
  # possible and so it has been named "give_back"
  def give_back(book)
    @books.delete(book)
  end

  def get_books
    @books
  end

  def send_overdue_notice(notice)
    "#{@name}: #{notice}"
  end
end

class Book
  def initialize(id, title, author)
    # int_check id
    @id = id
    @title = title
    @author = author
    @due_date = nil
  end

  def get_id
    @id
  end

  def get_title
    @title
  end

  def get_author
    @author
  end

  def get_due_date
    @due_date
  end

  def check_out(due_date)
    # int_check due_date
    @due_date = due_date
    #nil
  end

  def check_in
    @due_date = nil
  end

  def to_s
    "#{@id}: #{@title}, by #{@author}"
  end

  #def int_check(num)
  #  raise Exception, "One or more numeric values are required for this operation, which you didn't provide" if num.to_i == 0
  #end
  #private :int_check
end

class Library
  include Singleton
  #attr_reader :calendar, :books, :members
  attr_reader :collection, :members

  def initialize
    @collection = []
    book_id = 1
    file = File.open('collection.txt')
    until file.eof
      line = file.readline
      title, comma, author = line[1..-3].rpartition(',')
      book = Book.new(book_id, title, author)
      @collection.push(book)
      book_id += 1
    end
    @calendar = Calendar.instance
    @members = {}
    @current_member = nil
    @open = false
  end

  def self.reset
    @singleton__instance__ = nil
  end

  def open
    raise Exception, 'The library is already open!' if @open
    @calendar.advance
    @open = true
    "Today is day #{@calendar.get_date}."
  end

  def find_all_overdue_books
    result = ''
    @members.each do |name, member|
      overdue_found = false   #no overdue items found for member yet
      member.get_books.each do |book|
        if book.get_due_date < @calendar.get_date
          if overdue_found
            result += "\t#{book.to_s}\n"
          else                #first overdue item so add member name to result
            overdue_found = true
            result += "#{name}:\n\t#{book.to_s}\n"
          end
        end
      end
    end
    if result.length < 1
      result = 'No books are overdue.'
    end
    result
  end

  def issue_card(name_of_member)
    raise Exception, 'The library is not open.' unless @open
    if @members.include? name_of_member
      "#{name_of_member} already has a library card."
    else
      @members[name_of_member] = Member.new(name_of_member, self)
      "Library card issued to #{name_of_member}"
    end
  end

  def serve(name_of_member)
    raise Exception, 'The library is not open.' unless @open
    if @members.include? name_of_member
      @current_member = @members[name_of_member]
      "Now serving #{name_of_member}."
    else
      "#{name_of_member} does not have a library card."
    end
  end

  def find_overdue_books
    raise Exception, 'The library is not open.' unless @open
    if @current_member == nil
      raise Exception, 'No member is currently being served.'
    else
      any_overdue = false
      result = "\nOverdue books for #{@current_member.get_name}: \n"
      @current_member.get_books.each do |book|
        if book.get_due_date < @calendar.get_date
          any_overdue = true
          result += "\t#{book.to_s}\n"
        end
      end
      unless any_overdue
        result += "\tNone\n"
      end
      result
    end
  end

  #TEST ME ***
  def check_in(*book_numbers)
    raise Exception, 'The library is not open.' unless @open
    raise Exception, 'No member is currently being served.' if @current_member == nil
    @members_books = @current_member.get_books
    book_numbers.each do |id|
      @members_books.each do |book|
        raise Exception, "The member does not have book #{id}." unless id == book.get_id
      end
    end
    if book_numbers.size >= 1
      book_numbers.each do |id|
        @members_books.each do |book|
          if book.get_id == id
            book.check_in
            @collection.push(book)
            @current_member.give_back(book)
          end
        end
      end
    else
      return 'You must check in at least one book.'
    end
    "#{@current_member.get_name} has returned #{book_numbers.size} books."
  end

  def search(string)
    if string.size < 4
      'Search string must contain at least four characters.'
    else
      string.downcase!
      result = ''
      @collection.each do |book|
        title = book.get_title.downcase
        author = book.get_author.downcase
        if title.include?(string) || author.include?(string)
          unless result.include?("#{book.get_title}, by #{book.get_author}")
            result.concat("#{book.to_s}\n")
          end
        end
      end
      if result.length < 1
        return 'No books found.'
      else
        return result
      end
    end
  end

  def check_out(*book_ids)
    raise Exception, 'The library is not open.' unless @open
    raise Exception, 'No member is currently being served.' if @current_member == nil
    if (@current_member.get_books.size + book_ids.size) > 3 || book_ids.size > 3
      return 'Members cannot check out more than 3 books.'
    end
    if book_ids.size >= 1 && book_ids.size <= 3
      valid_id = false
      book_ids.each do |id|
        @collection.each do |book|
          if book.get_id == id
            book = @collection[id - 1]
            book.check_out(@calendar.get_date + 7)
            @current_member.check_out(book)
            @collection.delete(book)
            valid_id = true
          end
        end
        raise Exception, "The library does not have book #{id}." unless valid_id
      end
    else
      return 'You must check out at least one book.'
    end
    "#{book_ids.size} books have been checked out to #{@current_member.get_name}."
  end

  #TEST ME ***
  def renew(*book_ids)
    raise Exception, 'The library is not open.' unless @open
    raise Exception, 'No member is currently being served.' if @current_member == nil
    if book_ids.size < 1
      'Please specify at least one book id to renew.'
    else
      book_ids.each do |id|
        valid_id = false
        @current_member.get_books.each do |book|
          if book.get_id == id
            book.check_out(@calendar.get_date + 7)
            valid_id = true
          end
        end
        raise "The member does not have book #{id}." unless valid_id
      end
    end
    "#{book_ids.size} books have been renewed for #{@current_member.get_name}."
  end

  def close
    if @open
      @open = false
      'Good night.'
    else
      raise Exception, 'The library is not open.'
    end
  end

  def quit
    @open = false
    'The library is now closed for renovations.'
  end
end