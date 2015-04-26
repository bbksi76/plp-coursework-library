require './library'
require 'test/unit'

class TestCalendar < Test::Unit::TestCase
  def setup
    @cal = Calendar.instance
  end

  def teardown
    Singleton.__init__(@cal)
  end

  def test_initialize_and_advance
    assert_equal(0, @cal.get_date)
    assert_equal(1, @cal.advance)
  end
end

class TestBook < Test::Unit::TestCase
  def setup
    @book = Book.new(1, 'Pride and Prejudice', 'Jane Austen')
  end

  def teardown
    @book = nil
  end

  def test_initialize
    assert_equal(1, @book.get_id)
    assert_equal('Pride and Prejudice', @book.get_title)
    assert_equal('Jane Austen', @book.get_author)
    assert_equal(nil, @book.get_due_date)
  end

  def test_check_out
    assert_equal(nil, @book.get_due_date)
    @book.check_out(3)
    assert_equal(3, @book.get_due_date)
  end

  def test_check_in
    assert_nil(@book.check_in)
  end

  def test_to_s
    assert_equal('1: Pride and Prejudice, by Jane Austen', @book.to_s)
  end
end

class TestMember < Test::Unit::TestCase
  def setup
    @lib = Library.instance
    @member = Member.new('Bruce Banner', @lib)
    @book = Book.new(1, 'Pride and Prejudice', 'Jane Austen')
  end

  def teardown
    @member = nil
    @book = nil
    Singleton.__init__(@lib)
  end

  def test_initialize
    assert_equal('Bruce Banner', @member.get_name)
    assert_equal([], @member.get_books)
  end

  def test_check_out
    assert_equal([], @member.get_books)
    temp = Array.new(1, @book)
    assert_equal(temp, @member.check_out(@book))
  end

  def test_give_back
    @member.check_out(@book)
    @member.give_back(@book)
    assert_equal([], @member.get_books)
  end

  def test_send_overdue_notice
    assert_equal('Bruce Banner: you have overdue books, please return/renew them.',
                 @member.send_overdue_notice('you have overdue books, please return/renew them.'))
  end
end

class TestLibrary < Test::Unit::TestCase
  def setup
    @lib = Library.instance
  end

  def teardown
    Library.reset
    Calendar.reset
  end

  def test_initialize
    @cal = Calendar.instance
    #puts @cal.get_date
    #@lib.open
    #puts @cal.get_date
    assert_equal(0, @lib.members.size)
    assert_equal(115, @lib.collection.size)
  end

  def test_open_when_closed
    @cal = Calendar.instance
    assert_equal('Today is day 1.', @lib.open)
  end

  def test_open_when_open
    @cal = Calendar.instance
    @lib.open
    temp_exception = assert_raise(Exception) {@lib.open}
    assert_equal('The library is already open!', temp_exception.message)
  end

  def test_close_when_closed
    @cal = Calendar.instance
    @lib.open
    @lib.close
    temp_exception = assert_raise(Exception) {@lib.close}
    assert_equal('The library is not open.', temp_exception.message)
  end

  def test_close_when_open
    @cal = Calendar.instance
    @lib.open
    assert_equal('Good night.', @lib.close)
  end

  def test_issue_card_library_closed
    @cal = Calendar.instance
    @lib.open
    @lib.close
    temp_exception = assert_raise(Exception) {@lib.issue_card('member')}
    assert_equal('The library is not open.', temp_exception.message)
  end

  def test_issue_card_has_card
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    assert_equal('Bruce Banner already has a library card.', @lib.issue_card('Bruce Banner'))
  end

  def test_issue_card
    @cal = Calendar.instance
    @lib.open
    assert_equal(0, @lib.members.size)
    assert_equal('Library card issued to Bruce Banner', @lib.issue_card('Bruce Banner'))
    assert_equal(1, @lib.members.size)
  end

  def test_check_in_closed
    @cal = Calendar.instance
    @lib.open
    @lib.close
    temp_exception = assert_raise(Exception) {@lib.check_in}
    assert_equal('The library is not open.', temp_exception.message)
  end

  def test_check_in_no_member
    @cal = Calendar.instance
    @lib.open
    temp_exception = assert_raise(Exception) {@lib.check_in}
    assert_equal('No member is currently being served.', temp_exception.message)
  end

  def test_check_in_zero
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    assert_equal('You must check in at least one book.', @lib.check_in)
  end

  def test_check_in_invalid
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    @lib.check_out(1, 2)
    temp_exception = assert_raise(Exception) {@lib.check_in(9999)}
    assert_equal('The member does not have book 9999.', temp_exception.message)
  end

  def test_check_in_one
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    @lib.check_out(3)
    assert_equal('Bruce Banner has returned 1 books.', @lib.check_in(3))
  end

  def test_check_in_three
    @cal = Calendar.instance
    @member = Member.new('Bruce Banner', @lib)
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    @lib.check_out(1, 2, 3)
    books = @member.get_books
    books.each do |b|
      b.get_title
    end
    #assert_equal('Bruce Banner has returned 3 books.', @lib.check_in(1, 2, 3))
  end

  def test_serve_library_closed
    @cal = Calendar.instance
    @lib.open
    @lib.close
    temp_exception = assert_raise(Exception) {@lib.serve('Bruce Banner')}
    assert_equal('The library is not open.', temp_exception.message)
  end

  def test_serve_no_card
    @cal = Calendar.instance
    @lib.open
    assert_equal('Bruce Banner does not have a library card.', @lib.serve('Bruce Banner'))
  end

  def test_serve
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    assert_equal('Now serving Bruce Banner.', @lib.serve('Bruce Banner'))
  end

  def test_check_out_closed
    @cal = Calendar.instance
    @lib.open
    @lib.close
    temp_exception = assert_raise(Exception) {@lib.check_out}
    assert_equal('The library is not open.', temp_exception.message)
  end

  def test_check_out_no_member
    @cal = Calendar.instance
    @lib.open
    temp_exception = assert_raise(Exception) {@lib.check_out}
    assert_equal('No member is currently being served.', temp_exception.message)
  end

  def test_check_out_over_3
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    assert_equal('Members cannot check out more than 3 books.', @lib.check_out(1, 2, 3, 4))
  end

  def test_check_out_2_then_2
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    assert_equal('2 books have been checked out to Bruce Banner.', @lib.check_out(1, 2))
    assert_equal('Members cannot check out more than 3 books.', @lib.check_out(3, 4))
  end

  def test_check_out_zero
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    assert_equal('You must check out at least one book.', @lib.check_out)
  end

  def test_check_out_invalid
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    temp_exception = assert_raise(Exception) {@lib.check_out(9999)}
    assert_equal('The library does not have book 9999.', temp_exception.message)
  end

  def test_check_out_one
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    assert_equal('1 books have been checked out to Bruce Banner.', @lib.check_out(1))
  end

  def test_check_out_three
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    assert_equal('3 books have been checked out to Bruce Banner.', @lib.check_out(1, 2, 3))
  end

  def test_find_overdue_books_closed
    @cal = Calendar.instance
    @lib.open
    @lib.close
    temp_exception = assert_raise(Exception) {@lib.find_overdue_books}
    assert_equal('The library is not open.', temp_exception.message)
  end

  def test_find_overdue_bks_nil_mem
    @cal = Calendar.instance
    @lib.open
    temp_exception = assert_raise(Exception) {@lib.find_overdue_books}
    assert_equal('No member is currently being served.', temp_exception.message)
  end

  def test_find_overdue_bks_no_books
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    assert_equal("\nOverdue books for Bruce Banner: \n\tNone\n", @lib.find_overdue_books)
  end

  def test_find_overdue_bks_no_over
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    @lib.check_out(3)
    assert_equal("\nOverdue books for Bruce Banner: \n\tNone\n", @lib.find_overdue_books)
  end

  def test_find_overdue_books
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    @lib.check_out(3)
    8.times {@cal.advance}
    @lib.check_out(9)
    assert_equal("\nOverdue books for Bruce Banner: \n\t3: Alice's Adventures in Wonderland, by Lewis Carroll\n", @lib.find_overdue_books)
  end

  def test_find_overdue_books_ret
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    @lib.check_out(3)
    8.times {@cal.advance}
    @lib.check_in(3)
    @lib.check_out(9)
    assert_equal("\nOverdue books for Bruce Banner: \n\tNone\n", @lib.find_overdue_books)
  end

  def test_find_all_overdue_none
    @cal = Calendar.instance
    @lib.open
    assert_equal('No books are overdue.', @lib.find_all_overdue_books)
  end

  def test_find_all_overdue_one
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    @lib.check_out(9)
    8.times {@cal.advance}
    msg = "Bruce Banner:\n\t9: The Yellow Wallpaper, by Charlotte Perkins Gilman\n"
    assert_equal(msg, @lib.find_all_overdue_books)
  end

  def test_find_all_overdue_2m_1o
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    @lib.check_out(9)
    @lib.issue_card('Clark Kent')
    @lib.serve('Clark Kent')
    @lib.check_out(3)
    8.times {@cal.advance}
    msg = "Bruce Banner:\n\t9: The Yellow Wallpaper, by Charlotte Perkins Gilman\nClark Kent:\n\t3: Alice's Adventures in Wonderland, by Lewis Carroll\n"
    assert_equal(msg, @lib.find_all_overdue_books)
  end

  def test_find_all_overdue_1m_2o
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    @lib.check_out(9)
    @lib.check_out(3)
    8.times {@cal.advance}
    msg = "Bruce Banner:\n\t9: The Yellow Wallpaper, by Charlotte Perkins Gilman\n\t3: Alice's Adventures in Wonderland, by Lewis Carroll\n"
    assert_equal(msg, @lib.find_all_overdue_books)
  end

  def test_search_arg_too_short
    @cal = Calendar.instance
    @lib.open
    assert_equal('Search string must contain at least four characters.', @lib.search('zz'))
  end

  def test_search_not_found
    @cal = Calendar.instance
    @lib.open
    assert_equal('No books found.', @lib.search('zzzz'))
  end

  def test_search_book_borrowed
    @cal = Calendar.instance
    @lib.open
    @lib.issue_card('Bruce Banner')
    @lib.serve('Bruce Banner')
    @lib.check_out(9)
    assert_equal('No books found.', @lib.search('pape'))
  end

  def test_search_title
    @cal = Calendar.instance
    @lib.open
    assert_equal("9: The Yellow Wallpaper, by Charlotte Perkins Gilman\n", @lib.search('pape'))
  end

  def test_search_author
    @cal = Calendar.instance
    @lib.open
    assert_equal("12: A Doll's House : a play, by Henrik Ibsen\n", @lib.search('doll'))
  end

  def test_search_capitals
    @cal = Calendar.instance
    @lib.open
    assert_equal("9: The Yellow Wallpaper, by Charlotte Perkins Gilman\n", @lib.search('gilman'))
    assert_equal("9: The Yellow Wallpaper, by Charlotte Perkins Gilman\n", @lib.search('GiLmAn'))
  end

  def test_search_multiple_copies
    @cal = Calendar.instance
    @lib.open
    assert_equal("81: Around the World in Eighty Days, by Jules Verne\n", @lib.search('ules'))
  end

  def renew(*book_ids)

  end

  def quit

  end

end



