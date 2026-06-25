import 'package:sembast_web/sembast_web.dart';

class WebDatabase {
  static const String defaultDatabaseName = 'aonw_web.db';
  static const int schemaVersion = 1;

  final Database database;

  const WebDatabase(this.database);

  static Future<WebDatabase> open({
    String name = defaultDatabaseName,
    DatabaseFactory? factory,
  }) async {
    final resolvedFactory = factory ?? databaseFactoryWeb;
    final database = await resolvedFactory.openDatabase(
      name,
      version: schemaVersion,
    );
    return WebDatabase(database);
  }

  Future<void> close() => database.close();
}
