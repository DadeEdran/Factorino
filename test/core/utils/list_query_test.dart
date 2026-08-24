import 'package:factorino/core/utils/list_query.dart';
import 'package:flutter_test/flutter_test.dart';

/// The paging window every list screen drives its query from.
///
/// Small enough to look obviously correct, which is exactly why it is worth
/// testing: the one behaviour that is easy to get wrong — a search that
/// inherits the scrolled-to window — produces no error, just a query for two
/// thousand matches of three letters.
void main() {
  test('starts at one page with no term', () {
    const ListQuery query = ListQuery();
    expect(query.limit, ListQuery.defaultPageSize);
    expect(query.term, '');
    expect(query.isSearching, isFalse);
  });

  test('loading more widens the window by exactly one page', () {
    const ListQuery first = ListQuery();
    final ListQuery second = first.loadingMore();
    final ListQuery third = second.loadingMore();

    expect(second.limit, ListQuery.defaultPageSize * 2);
    expect(third.limit, ListQuery.defaultPageSize * 3);
    expect(third.term, '');
  });

  test('searching resets the window to one page', () {
    // The behaviour this whole value type exists for. Held as one object so
    // the term and the limit cannot change in separate frames.
    final ListQuery scrolled = const ListQuery()
        .loadingMore()
        .loadingMore()
        .loadingMore();
    expect(scrolled.limit, ListQuery.defaultPageSize * 4);

    final ListQuery searched = scrolled.searching('علی');
    expect(searched.limit, ListQuery.defaultPageSize);
    expect(searched.term, 'علی');
    expect(searched.isSearching, isTrue);
  });

  test('paging continues from the reset window after a search', () {
    final ListQuery searched = const ListQuery().searching('علی').loadingMore();
    expect(searched.limit, ListQuery.defaultPageSize * 2);
    expect(searched.term, 'علی');
  });

  test('a whitespace-only term is not a search', () {
    // Otherwise a stray space in the field switches the screen to its
    // "nothing matched" empty state while the list underneath is full.
    expect(const ListQuery(term: '   ').isSearching, isFalse);
    expect(const ListQuery(term: '‌').isSearching, isTrue);
  });

  test('hasMoreAfter is true only when the page came back full', () {
    const ListQuery query = ListQuery();
    expect(query.hasMoreAfter(ListQuery.defaultPageSize), isTrue);
    expect(query.hasMoreAfter(ListQuery.defaultPageSize - 1), isFalse);
    expect(query.hasMoreAfter(0), isFalse);
  });

  test('equal windows compare equal, so a rebuild does not re-query', () {
    expect(const ListQuery(), const ListQuery());
    expect(const ListQuery().hashCode, const ListQuery().hashCode);
    expect(const ListQuery(term: 'a'), isNot(const ListQuery(term: 'b')));
    expect(
      const ListQuery(),
      isNot(const ListQuery(limit: ListQuery.defaultPageSize * 2)),
    );
  });

  test('toString carries no user text', () {
    // A search term is something the user typed about a third party -- a
    // customer's name, most often. §7 keeps it out of anything that could be
    // interpolated into a log line, and toString is the usual route.
    final String text = const ListQuery(term: 'خسرو رضایی').toString();
    expect(text, isNot(contains('خسرو')));
    expect(text, contains('10 chars'));
  });
}
