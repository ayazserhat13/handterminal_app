class Fb10Commands {
  static const int handshakeWake = 0x00;
  static const int handshakeRequest = 0x03;
  static const int handshakeAck = 0xAA;
  static const int handshakeResponse = 0xBB;
  static const int startTerminal = 0x50;
  static const int idle = 0xAF;

  static const int menu = 0xA3;
  static const int monitor = 0xA5;
  static const int errors = 0xA6;
  static const int quit = 0xA7;
  static const int down = 0xAB;
  static const int up = 0xAD;
  static const int enter = 0xAE;

  static const List<int> singleByteEchoes = [
    handshakeWake,
    handshakeRequest,
    startTerminal,
    handshakeAck,
  ];
}

class Fb10Timings {
  static const Duration handshakeRetryInterval = Duration(milliseconds: 250);
  static const Duration handshakeCommandGap = Duration(milliseconds: 40);
  static const Duration firstIdlePollDelay = Duration(milliseconds: 60);
  static const Duration idlePollInterval = Duration(milliseconds: 500);
  static const Duration repeatKeyDelay = Duration(milliseconds: 60);
  static const Duration keyPressDuration = Duration(milliseconds: 160);
  static const Duration keyReleaseGuard = Duration(milliseconds: 250);
  static const Duration idleAfterKeyGuard = Duration(milliseconds: 300);
}
