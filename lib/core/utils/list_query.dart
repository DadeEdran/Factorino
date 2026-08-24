/// The window a paginated list is currently asking the database for.
///
/// the project spec: *"Lazy/virtualized lists everywhere. Paginate large lists
/// at the query level."* Virtualization alone is not enough — a
/// `ListView.builder` over ten thousand rows builds only the visible widgets,
/// but the query behind it still loaded ten thousand rows, mapped them all to
/// domain models and holds them in memory. The limit has to reach SQL, and this
/// is the value that carries it there.
///
/// Immutable and comparable, so a provider rebuilding with an identical window
/// does not re-issue the query.
class ListQuery {
  const ListQuery({this.term = '', this.limit = defaultPageSize});

  /// One screenful with room to spare on a desktop table, which is the tier
  /// that shows the most rows at once. Small enough that the first paint is
  /// fast on a phone.
  static const int defaultPageSize = 40;

  /// The search term as typed. Folding it is the repository's job, through the
  /// one normalizer (D-029) — doing it here would be a second normalizer.
  final String term;

  /// How many rows the query may return.
  final int limit;

  bool get isSearching => term.trim().isNotEmpty;

  /// A new search. **The window resets to one page**, which is the whole reason
  /// this is one value rather than two providers: a user who scrolled through
  /// two thousand rows and then typed three letters should not have the app ask
  /// for two thousand matches of those letters.
  ListQuery searching(String value) => ListQuery(term: value);

  /// One more page. Growing the limit rather than advancing an offset is
  /// deliberate: the underlying read is a live query, and a stream per offset
  /// page would have to be merged and re-merged on every write, with rows able
  /// to shift between pages in between. One widening window over one stream
  /// stays consistent with itself.
  ListQuery loadingMore() =>
      ListQuery(term: term, limit: limit + defaultPageSize);

  /// Whether a full page came back, i.e. there may be more behind it.
  ///
  /// Cheaper than a `COUNT(*)` per page and exact enough for a load-more
  /// affordance: the one case it gets wrong is a total that is an exact
  /// multiple of the page size, where the user is offered one more page that
  /// turns out to be empty.
  bool hasMoreAfter(int received) => received >= limit;

  @override
  bool operator ==(Object other) =>
      other is ListQuery && other.term == term && other.limit == limit;

  @override
  int get hashCode => Object.hash(term, limit);

  @override
  String toString() => 'ListQuery(limit: $limit, term: ${term.length} chars)';
}
