# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;

use_ok("Lucene::QueryParser");

use Data::Dumper;
is_deeply(parse_query("foo"),
[ { query => 'TERM', type => 'NORMAL', term => 'foo' } ],
    "Simple one-word query parses fine");
is_deeply(parse_query("foo bar"),
[ { query => 'TERM', type => 'NORMAL', term => 'foo' },
  { query => 'TERM', type => 'NORMAL', term => 'bar' },
 ],
    "Simple two-word query parses fine");
is_deeply(parse_query("foo +bar"),
[ { query => 'TERM', type => 'NORMAL', term => 'foo' },
  { query => 'TERM', type => 'NORMAL', term => 'bar', type => "REQUIRED" },
 ],
    "+ operator works");
is_deeply(parse_query("foo -bar"),
[ { query => 'TERM', type => 'NORMAL', term => 'foo' },
  { query => 'TERM', type => 'NORMAL', term => 'bar', type => "PROHIBITED" },
 ],
    "- operator works");

is_deeply(parse_query("foo not bar"),
[ { query => 'TERM', type => 'NORMAL', term => 'foo' },
  { query => 'TERM', type => 'NORMAL', term => 'bar', type => "PROHIBITED" },
 ],
    "not operator works");

is_deeply(parse_query('"foo bar" baz'),
[ { query => 'PHRASE', type => 'NORMAL', term => 'foo bar' },
  { query => 'TERM', type => 'NORMAL', term => 'baz',},
 ],
    "Quoted phrase matches work");

is_deeply(parse_query("foo and bar"),
[ { query => 'TERM', type => 'NORMAL', term => 'foo' },
  { query => 'TERM', type => 'NORMAL', term => 'bar' },
 ],
    "conjunctions work");

is_deeply(parse_query("foo and baz:bar"),
[ { query => 'TERM', type => 'NORMAL', term => 'foo' },
  { query => 'TERM', type => 'NORMAL', term => 'bar', field => 'baz' },
 ],
    "fields work");

is_deeply(parse_query("foo and baz^2.0"),
[ { query => 'TERM', type => 'NORMAL', term => 'foo' },
  { query => 'TERM', type => 'NORMAL', term => 'baz', boost => "2.0" },
 ],
    "boosting works");

# Grand finale!

is_deeply(parse_query("red and yellow and -(coat:pink and green)"),
[ { query => 'TERM', type => 'NORMAL', term => 'red' },
  { query => 'TERM', type => 'NORMAL', term => 'yellow' },
  { subquery => [
        { query => 'TERM', type => 'NORMAL', term => 'pink', field => 'coat' },
        { query => 'TERM', type => 'NORMAL', term => 'green' } 
    ], query => 'SUBQUERY', type => 'PROHIBITED' }
], "A very complex query (with subquery)");

