import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Client-generated ids so rows can be created before the backend answers.
String newId() => _uuid.v4();
