require 'singleton'

class Calendar
  include Singleton
  # ...
  def initialize
    @date = 0     # set calendar to day 0
  end

  def self.reset
    @singleton__instance__ = nil    # allow deletion of the calendar instance during testing
  end

  def get_date
    @date
  end

  def advance
    @date += 1
  end
end

class Member
  def initialize(name, library)
    @name = name          # member's name
    @library = library    # point at library object that Member is a member of
    @books = []           # stores the library books the Member current has out on loan
  end

  def get_name
    @name
  end

  def check_out(book)
    @books.push(book)
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
    @id = id            # unique ID of Book
    @title = title
    @author = author
    @due_date = nil     # when a Book is available for loan it has no due date
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
    @due_date = due_date
  end

  def check_in
    @due_date = nil
  end

  def to_s        # override default to_s method
    "#{@id}: #{@title}, by #{@author}"
  end
end

class Library
  include Singleton
  attr_reader :collection, :members

  def initialize
    @collection = []          # stores all Books in the library available for loan
    book_id = 1               # variable to assign unique IDs to Books
    file = File.open('collection.txt')    # collection.txt holds the books to add to the library on initial open
    until file.eof
      line = file.readline
      title, comma, author = line[1..-3].rpartition(',')  # split line at the last comma, discarding it
      book = Book.new(book_id, title, author)
      @collection.push(book)
      book_id += 1
    end
    @calendar = Calendar.instance   # create the Calendar instance
    @members = {}                   # store all Members of the library
    @current_member = nil           # stores the member currently being served by the system
    @open = false                   # shows whether library is open or not
  end

  def self.reset                    # allow deletion of the library instance during testing
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
    @members.each do |name, member|                 # go through all members
      overdue_found = false                         # shows whether any overdue items were found for current member yet
      member.get_books.each do |book|               # go through each book held by current member
        if book.get_due_date < @calendar.get_date   # if book is overdue...
          if overdue_found                          # ...& not the 1st item overdue, output just book details
            result += "\t#{book.to_s}\n"
          else                                      # ... if 1st overdue item, output member name & book details
            overdue_found = true
            result += "#{name}:\n\t#{book.to_s}\n"
          end
        end
      end
    end
    if result.length < 1        # if no overdue books found for any members
      result = 'No books are overdue.'
    end
    result
  end

  def issue_card(name_of_member)
    raise Exception, 'The library is not open.' unless @open
    if @members.include? name_of_member       # check if they are already a member
      "#{name_of_member} already has a library card."
    else
      @members[name_of_member] = Member.new(name_of_member, self)
      "Library card issued to #{name_of_member}"
    end
  end

  def serve(name_of_member)
    raise Exception, 'The library is not open.' unless @open
    if @members.include? name_of_member     # if a member of the library serve that person
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
          any_overdue = true    # show overdue item found
          result += "\t#{book.to_s}\n"
        end
      end
      unless any_overdue    # no overdue items found
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
    unless book_numbers.size >= 1
      return 'You must check in at least one book.'
    else
      if @members_books.size < 1
        return "The member doesn't currently have any books out on loan"
      end
      book_numbers.each do |id|
        @members_books.each do |book|
          raise Exception, "The member does not have book #{id}." unless id == book.get_id
        end
      end
      book_numbers.each do |id|
        @members_books.each do |book|
          if book.get_id == id        # if member has that book, check it back into the library
            book.check_in
            @collection.push(book)
            @current_member.give_back(book)
          end
        end
      end
    end
    "#{@current_member.get_name} has returned #{book_numbers.size} books."
  end

  def search(string)
    if string.size < 4
      'Search string must contain at least four characters.'
    else
      string.downcase!                            # ignore case of search string
      result = ''
      @collection.each do |book|                  # go through whole library collection
        title = book.get_title.downcase           # ignore case of title
        author = book.get_author.downcase         # ignore case of author
        if title.include?(string) || author.include?(string)
          unless result.include?("#{book.get_title}, by #{book.get_author}")
            result.concat("#{book.to_s}\n")       # add to results if not already there
          end
        end
      end
      if result.length < 1                        # no search results found
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
    book_ids.sort.reverse!  # reverse sort IDs so when multiple books removed from collection, removes correct elements
    if book_ids.size >= 1 && book_ids.size <= 3
      book_ids.each do |id|
        valid_id = false                              # shows if book id is currently in library collection
        @collection.each do |book|
          if book.get_id == id
            valid_id = true                           # if book is in library collection mark as valid
          end
        end
        raise Exception, "The library does not have book #{id}." unless valid_id
      end
    else
      return 'You must check out at least one book.'
    end
    book_ids.each do |id|         # all IDs were valid so do the checking out
      book = @collection[id - 1]
      book.check_out(@calendar.get_date + 7)
      @current_member.check_out(book)           # store book with member
      @collection.delete(book)                  # remove from the library collection
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

  # From the name of this method I was expecting to shutdown the entire library, i.e. empty the library
  # book collection, clear the member list but from the description it just says to close the library
  # and display a message
  def quit
    @open = false
    'The library is now closed for renovations.'
  end
end