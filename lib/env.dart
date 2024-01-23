import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied()
abstract class Env {
  @EnviedField(varName: 'BOT_TOKEN', obfuscate: true)
  static final String botToken = _Env.botToken;
}
