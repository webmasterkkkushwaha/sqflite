# Dev tips

## Debugging

Unfortunately at this point, we cannot use sqflite in unit test.
Here are some debugging tips when you encounter issues:

### Try the experimental Logger

**Experimental feature**

The easiest is to wrap the factory you are using with `SqfliteDatabaseFactoryLogger`

```dart
import 'package:sqflite_common/sqflite_logger.dart';

Future<void> main() async {
  var factoryWithLogs = SqfliteDatabaseFactoryLogger(databaseFactory,
          options: SqfliteLoggerOptions(
                  type: SqfliteDatabaseFactoryLoggerType.all));
  var db = await factoryWithLogs.openDatabase(inMemoryDatabasePath,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: (db, _) {
                db.execute('''
  CREATE TABLE Product (
    id TEXT PRIMARY KEY,
    title TEXT
   )''');
          }));
  await db.close();
}
```

The code above should print something like:

```
openDatabase:({path: :memory:, options: {readOnly: false, singleInstance: true, version: 1}, sw: 0:00:00.009744})
query(query:({db: 1, sql: PRAGMA user_version, result: [{user_version: 0}], sw: 0:00:00.006656}))
execute(execute:({db: 1, sql: BEGIN EXCLUSIVE, result: {transactionId: 1}, sw: 0:00:00.001008}))
query(query:({db: 1, txn: 1, sql: PRAGMA user_version, result: [{user_version: 0}], sw: 0:00:00.000166}))
execute(execute:({db: 1, txn: 1, sql:   CREATE TABLE Product (
    id TEXT PRIMARY KEY,
    title TEXT
   ), sw: 0:00:00.000228}))
execute(execute:({db: 1, txn: 1, sql: PRAGMA user_version = 1, sw: 0:00:00.000057}))
execute(execute:({db: 1, txn: 1, sql: COMMIT, sw: 0:00:00.000138}))
closeDatabase:({db: 1, sw: 0:00:00.001952})
```

The logger allows for a callback to choose how to keep/display the logs.

A quick way to enable logging with a warning can be done using:

```dart
var factoryWithLogs = factory.debugQuickLoggerWrapper();
```

Or if using sqflite default factory, you can enable global logging using:
```dart
databaseFactory = databaseFactory.debugQuickLoggerWrapper();
```

### Turn on SQL console logging (old)

Temporarily turn on SQL logging on the console by adding the following call in your code before opening the first database

````dart
import 'package:sqflite_common/sqflite_dev.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  // Turn logging on
  await databaseFactory.setLogLevel(sqfliteLogLevelVerbose);
}
````

This call is `deprecated` on purpose to prevent keeping it in your app

### List existing tables

This will print all existing tables, views, index, trigger and their schema (`CREATE` statement).
You might see some system table (`sqlite_sequence` as well as `android_metadata` on Android)


````dart
print(await db.query("sqlite_master"));
````

### Dump a table content

you can simply dump an existing table content:

````dart
print(await db.query("my_table"));
````

## Unit tests

Errors in SQL statement are sometimes hard to debug, especially during migration where the status/schema
of the database can change.

As much as you can, try to extract your database logic using an abstract databaseFactory and database path
to allow unit tests using FFI during development:

Setup in `pubspec.yaml`:

```yaml
dev_dependencies:
  sqflite_common_ffi:
```

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  // Init ffi loader if needed.
  sqfliteFfiInit();
  test('MyUnitTest', () async {
    var factory = databaseFactoryFfi;
    var db = await factory.openDatabase(inMemoryDatabasePath);

    // Should fail table does not exists
    try {
      await db.query('Test');
    } on DatabaseException catch (e) {
      // no such table: Test
      expect(e.isNoSuchTableError('Test'), isTrue);
      print(e.toString());
    }

    // Ok
    await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY)');
    await db.execute('ALTER TABLE Test ADD COLUMN name TEXT');
    // should succeed, but empty
    expect(await db.query('Test'), []);

    await db.close();
  });
}
```
## Extract SQLite database on Android

In Android Studio (> 3.0.1)
* Open `Device File Explorer via View > Tool Windows > Device File Explorer`
* Go to `data/data/<package_name>/databases`, where `<package_name>` is the name of your package.
  Location might depends how the path was specified (assuming here that are using `getDatabasesPath` to get its base location)
* Right click on the database and select Save As.... Save it anywhere you want on your PC.

## WAL

### Enable WAL on Android

WAL is disabled by default on Android. Since sqflite v2.0.4-dev.1 You can turn it on by declaring the 
following in you app manifest (in the application object):

```xml
<application>
  ...
  <!-- Enable WAL -->
  <meta-data
    android:name="com.tekartik.sqflite.wal_enabled"
    android:value="true" />
  ...
</application>
```

Alternatively, a more conservative (multiplatform) way is to call during onConfigure:

```db
await db.execute('PRAGMA journal_mode=WAL')
```

As reported [here](https://github.com/tekartik/sqflite/issues/929) on sqflite Android, if the metadata is not set
in the manifest, the following should be used

```db
await db.rawQuery('PRAGMA journal_mode=WAL')
```

so something like that could be used, however, I do recommend setting the metadata in the manifest.

```dart
try {
  await db.execute('PRAGMA journal_mode=WAL');
} catch (e) {
  await db.rawQuery('PRAGMA journal_mode=WAL');
}
```

### Generic way of enabling WAL mode

As of `sqflite_common` 2.5.6, you can simply use during `onConfigure`:
```dart
onConfigure: (db) async {
  ...
  // Set the journal mode
  await db.setJournalMode('WAL');
  ...
}
```

## AUTO_VACUUM

`PRAGMA auto_vacuum = xxx` must be called before tables are created during `onConfigure` and before setting the WAL mode. In
`onConfigure` you can check the database version and if it is 0, you can assume the database is new.

```dart
onConfigure: (db) async {
  // Check the version to know if the database exists
  // auto_vacuum mode must be set before tables are created
  var version = await db.getVersion();
  if (version == 0) {
    await db.execute('PRAGMA auto_vacuum = 2');
  }
  ...
}
```

## setLocale on Android

Android has a specific setLocale API that allows sorting localized field according to a locale using query like:

```sql
SELECT * FROM Test ORDER BY name COLLATE LOCALIZED ASC
```

There is an extra Android only API to specify the locale to use:
```dart
await database.setLocale('fr-FR');
```

This API must be called during onConfigure (each time you open the database). The specified IETF BCP 47 language tag
string (en-US, zh-CN, fr-FR, zh-Hant-TW, ...) must be as defined in
`Locale.forLanguageTag` in Android/Java documentation.

```dart
var db = await openDatabase(path,
            onConfigure: (db) async {
              await db.androidSetLocale('zh-CN');
            },
            version: 1,
            onCreate: (db, v) async {
              await db.execute('CREATE TABLE Test(name TEXT)');
            });
// Localized sorting.
var result = await db.query('Test', orderBy: 'name COLLATE LOCALIZED ASC'));
```