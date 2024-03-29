import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:game/env.dart';
import 'package:http/http.dart' as http;
import 'package:svg_path_parser/svg_path_parser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        userId: 1114282009,
        messageId: 3,
        chatId: 1114282009,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.userId,
    required this.chatId,
    required this.messageId,
  });

  final int? userId;
  final int? chatId;
  final int? messageId;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  Path targetPath = parseSvgPath(
      'M 404 2 L 406 93 L 394 126 L 468 152 L 548 138 L 598 107 L 653 99 L 657 130 L 528 198 L 427 194 L 410 373 L 522 912 L 466 915 L 439 826 L 342 429 L 262 835 L 174 929 L 151 902 L 206 787 L 257 379 L 250 187 L 133 172 L 32 125 L 2 121 L 6 79 L 53 92 L 98 100 L 130 126 L 221 133 L 310 122 L 297 85 L 298 5 L 404 2 Z');
  Path shieldPath = Path();
  final targetSize = 300.0;
  final shieldSize = 100.0;
  int _tries = 3;
  int _score = 0;

  int _speed = 5000;

  double _volume = 1.0;

  final player = AudioPlayer();

  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      duration: Duration(milliseconds: _speed),
      vsync: this,
    );
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
        _controller.forward();
      }
    });

    _controller.duration = Duration(milliseconds: _speed);

    // scale the path
    var pathBounds = targetPath.getBounds();
    var k = targetSize / pathBounds.height;
    targetPath = targetPath.transform(Matrix4.diagonal3Values(k, k, 1).storage);
    // center the path
    pathBounds = targetPath.getBounds();
    var offset = Offset(
      (targetSize - pathBounds.width) / 2,
      (targetSize - pathBounds.height) / 2,
    );
    targetPath = targetPath.shift(offset);
    // correct the path
    const topPadding = 10.0;
    pathBounds = targetPath.getBounds();
    offset = const Offset(0, topPadding);
    targetPath = targetPath.shift(offset);
    pathBounds = targetPath.getBounds();
    k = (targetSize - topPadding) / pathBounds.height;

    targetPath = targetPath.transform(Matrix4.diagonal3Values(1, k, 1).storage);

    shieldPath.addOval(Rect.fromLTWH(0, 0, shieldSize, shieldSize));
    shieldPath = shieldPath.shift(Offset(
      (targetSize - shieldSize) / 2,
      (targetSize - shieldSize) / 2,
    ));

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('KILL MISHKOV'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  'Осталось попыток: $_tries',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  'Счёт: $_score',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: RotationTransition(
                turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
                child: SizedBox.square(
                  dimension: targetSize,
                  child: GestureDetector(
                    onTapDown: (details) {
                      final contains =
                          targetPath.contains(details.localPosition) &&
                              !shieldPath.contains(details.localPosition);
                      print(contains);
                      if (contains) {
                        setState(() {
                          _score += 10;
                          if (_controller.duration!.inMilliseconds > 200) {
                            _speed -= 100;
                          }
                          _controller.stop();
                          _controller.duration = Duration(milliseconds: _speed);
                          _controller.forward();
                        });
                        player.stop();
                        if (_volume != 0.0) {
                          player.play(
                            AssetSource('audio2.mp3'),
                            volume: _volume,
                          );
                        }
                      } else {
                        if (_tries == 1) {
                          endgame();
                        }
                        setState(() {
                          _tries--;
                        });
                        player.stop();
                        if (_volume != 0.0) {
                          player.play(
                            AssetSource('audio.mp3'),
                            volume: _volume,
                          );
                        }
                      }
                      // path.contains(point)
                    },
                    child: Stack(
                      children: [
                        Image.asset('assets/target.png'),
                        Center(
                          child: SizedBox.square(
                            dimension: shieldSize,
                            child: Image.asset('assets/shield.webp'),
                          ),
                        ),
                        if (kDebugMode)
                          CustomPaint(
                            painter: DebugPainter([
                              // targetPath,
                              // shieldPath,
                            ]),
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '* Играть со звуком',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                    ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() {
            if (_volume == 0.0) {
              _volume = 1.0;
            } else {
              _volume = 0.0;
            }
          });
        },
        child: Icon(
          _volume == 0.0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
        ),
      ),
    );
  }

  Future<void> resetgame() async {
    setState(() {
      _tries = 3;
      _score = 0;
      _speed = 5000;

      _controller.reset();
      _controller.duration = Duration(milliseconds: _speed);
      _controller.forward();
    });
  }

  Future<void> _reportScore() async {
    if (_score == 0) {
      return;
    }

    try {
      print(Uri.base);

      final maybeUserIdString = Uri.base.queryParameters['userId'];
      if (maybeUserIdString == null ||
          int.tryParse(maybeUserIdString) == null) {
        return;
      }
      final userId = int.parse(maybeUserIdString);

      final maybeInlineMessageId = Uri.base.queryParameters['inlineMessageId'];

      final maybeChatIdString = Uri.base.queryParameters['chatId'];
      int? maybeChatId;
      if (maybeChatIdString != null &&
          int.tryParse(maybeChatIdString) != null) {
        maybeChatId = int.tryParse(maybeChatIdString);
      }

      final maybeMessageIdString = Uri.base.queryParameters['messageId'];
      int? maybeMessageId;
      if (maybeMessageIdString != null &&
          int.tryParse(maybeMessageIdString) != null) {
        maybeMessageId = int.tryParse(maybeMessageIdString);
      }

      http.Response? response;
      if (maybeInlineMessageId != null) {
        response = await http.get(
          Uri(
            scheme: 'https',
            host: 'api.telegram.org',
            path: 'bot${Env.botToken}/setGameScore',
            queryParameters: {
              'user_id': userId.toString(),
              'score': _score.toString(),
              'inline_message_id': maybeInlineMessageId,
            },
          ),
        );
      } else {
        response = await http.get(
          Uri(
            scheme: 'https',
            host: 'api.telegram.org',
            path: 'bot${Env.botToken}/setGameScore',
            queryParameters: {
              'user_id': userId.toString(),
              'score': _score.toString(),
              'message_id': (maybeMessageId ?? 'NO_MESSAGE_ID').toString(),
              'chat_id': (maybeChatId ?? 'NO_CHAT_ID').toString(),
            },
          ),
        );
      }

      await _reportToBot(
          'set score request url: ${response.request?.url ?? 'NO_REQUEST_URL'}');
      await _reportToBot('set score status code: ${response.statusCode}');
      await _reportToBot(
          'set score reaseon phrase: ${response.reasonPhrase ?? 'NO_PHRASE'}');
      await _reportToBot('set score request body: ${response.body}');

      print(
          'set score request url ${response.request?.url ?? 'NO_REQUEST_URL'}');
      print('set score status code ${response.statusCode}');
      print('set score reaseon phrase ${response.reasonPhrase ?? 'NO_PHRASE'}');
      print('set score request body ${response.body}');

      // await _teleDart!.setGameScore(
      //   int.parse(maybeUserIdString),
      //   _score,
      //   inlineMessageId: maybeInlineMessageIdString,
      // );
    } catch (e) {
      _reportToBot('some errors occured');
      _reportToBot(e);
      print('some errors occured');
      print(e.toString());
    }
  }

  Future<void> _reportToBot(Object something) async {
    try {
      var message = (something).toString();
      if (message.isEmpty) {
        message = 'NO_CONTENT';
      }
      const adminChatId = 1114282009;
      final encodedMessage = Uri.encodeFull(message);
      final response = await http.get(
        Uri(
          scheme: 'https',
          host: 'api.telegram.org',
          path: 'bot${Env.botToken}/sendMessage',
          queryParameters: {
            'chat_id': adminChatId.toString(),
            'text': message,
          },
        ),
      );
      print(response.statusCode.toString());
      print(response.reasonPhrase ?? 'no phrase');
      print(response.body);
    } catch (e) {
      print('some errors occured when report to bot');
      print(e.toString());
    }
  }

  Future<void> endgame() async {
    _controller.reset();

    await _reportScore();

    if (!mounted) {
      return;
    }

    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Поражение'),
          contentPadding: const EdgeInsets.all(12),
          children: [
            Text('Конец! Ваш счёт: $_score'),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                resetgame();
              },
              child: const Text(
                'Повторить',
              ),
            ),
          ],
        );
      },
    );
  }
}

class DebugPainter extends CustomPainter {
  List<Path?> maybePaths;

  DebugPainter(this.maybePaths);

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in maybePaths) {
      if (path != null) {
        final paint = Paint()..color = Colors.red;
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
