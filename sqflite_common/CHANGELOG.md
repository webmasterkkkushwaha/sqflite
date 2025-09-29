## 2.5.6

* Add `Database.setJournalMode` extension helper method.
* Requires dart 3.8

## 2.5.5

* Requires dart 3.7

## 2.5.4+6

* Remove dependency on `dart:html`
* Add more keywords to escape from sqlite.org
* Export deprecated `SqfliteOptions` in sqflite_dev

## 2.5.3

* Export `databaseId` and `transactionId` in logger events.

## 2.5.2-1

* Start support for rolled back transaction by an inner statement.

## 2.5.1-2

* Add `readTransaction` support to `Database` to allow concurrent read-only transactions (sqlite_async only)
 
## 2.5.0+2

* Dart 3 only
* Add `readDatabaseBytes` and `writeDatabaseBytes` factory methods.

## 2.4.5+1

* Add global API from sqflite (openDatabase, deleteDatabase, databaseFactory...) from sqflite
* Fixes SqlBuilder for query with offset without limit.

## 2.4.4

* Dart 3 support

## 2.4.3

* add minimum support for SQLite uri (https://www.sqlite.org/uri.html)

## 2.4.2+2

* add experimental logger support.

## 2.4.1

* add support for `Batch.length` to help finding the last added operation index.
* strict-casts and sdk 2.18 support

## 2.4.0+2

* add support for `Database.queryCursor()` and `Database.rawQueryCursor()`
* base experimental web support
* Support for transaction v2

## 2.3.0

- Add `apply()` method to `Batch`. It will execute statements in that batch
  without starting a new transaction.

## 2.2.1+1

* Add debug tag to database factory

## 2.2.0

* Export `Object? result` in `DatabaseException`
* Export deprecated `DatabaseFactory.debugSetLogLevel` for quick logging.

## 2.1.0

* Requires dart sdk 2.15

## 2.0.1+1

* Truncate arguments in exception

## 2.0.0+2

* `nnbd` support
* Fix transaction ref counting on begin transaction failure

## 1.0.3+2

* Don't lock globally during open but lock per database full path.
 
## 1.0.2+1

* Don't create a transaction during openDatabase if not needed.

## 1.0.1

* Export `DatabaseException.getResultCode()`.

## 1.0.0+1

* Initial revision from sqflite 1.2.2+1
