import 'dart:convert';

class BluetoothProtocol {

  Function(String command, String data)? onPacketReceived;

  String createMessage({
    required String starter,
    required int length,
    required String command,
    String data = '',
    required String ender,
  }) {
    String lengthStr = length.toString().padLeft(3,'0');
    return "$starter$lengthStr$command$data$ender";
  }

  String createIdentifyMessage() {
    return createMessage(
      starter: '[',
      length: 6,
      command: 'IDF',
      data: '',
      ender: ']',
    );
  }

  String createSerialNumberMessage() {
    return createMessage(
      starter: '[',
      length: 6,
      command: 'SER',
      data: '',
      ender: ']',
    );
  }

  String createVersionMessage() {
    return createMessage(
      starter: '[',
      length: 6,
      command: 'VER',
      data: '',
      ender: ']',
    );
  }

  String createCountMessage(int pm, int count) {
    return createMessage(
      starter: '[',
      length: 13,
      command: 'CNT',
      data: "$pm${count.toString().padLeft(6, '0')}",
      ender: ']',
    );
  }

  String createStateMessage() {
    return createMessage(
      starter: '[',
      length: 6,
      command: 'STA',
      data: '',
      ender: ']',
    );
  }

  String createLogMessage() {
    return createMessage(
      starter: '[',
      length: 6,
      command: 'LOG',
      data: '',
      ender: ']',
    );
  }

  String _buffer = ""; // 데이터 조합을 위한 버퍼
  int _expectedLogCount = 0; // Log index
  Map<int, String> _logParts = {}; // Log current index에 따른 데이터 조각 저장

  void onDataReceived(List<int> rawData) {
    try {
      String receivedChunk = utf8.decode(rawData, allowMalformed: true);
      _buffer += receivedChunk;

      while (_buffer.contains('[') && _buffer.contains(']')) {
        int startIndex = _buffer.indexOf('[');
        int endIndex = _buffer.indexOf(']', startIndex);

        if (endIndex > startIndex) {
          String completePacket = _buffer.substring(startIndex, endIndex + 1);
          _parsePacket(completePacket);
          _buffer = _buffer.substring(endIndex + 1);

        } else {
          break;
        }
      }
    } catch (e) {
      print("Error while processing received data: $e");
    }
  }

  void _parsePacket(String packet) {
    try {
      if (packet.startsWith('[') && packet.endsWith(']')) {
        String payload = packet.substring(1, packet.length - 1);

        print("Complete Packet ASCII: $packet");

        String lengthStr = payload.substring(0, 3);
        int length = int.parse(lengthStr);
        String command = payload.substring(3, 6);
        String data = payload.substring(6);

        print("Parsed Packet:");
        print("Length: $length");
        print("Command: $command");
        print("Data: $data");

        if(onPacketReceived != null) {
          onPacketReceived!(command, data);
        }

        /*if (command == "LOG") {
          // Log index 추출 (2바이트)
          String logIndexStr = payload.substring(6, 8);
          _expectedLogCount = int.parse(logIndexStr, radix: 16); // 16진수 변환

          // Log current index 추출 (2바이트)
          String currentIndexStr = payload.substring(8, 10);
          int currentIndex = int.parse(currentIndexStr, radix: 16); // 16진수 변환

          // Log Data 추출 (나머지 데이터)
          String logData = payload.substring(10).trim();

          // 데이터 조합
          _logParts[currentIndex] = logData;
          print("Received Log Part - Index: $currentIndex, Data: $logData");

          // 모든 로그가 수신되었는지 확인
          if (_logParts.length == _expectedLogCount + 1) {
            _processCompleteLogData();
          }
        }*/
      } else {
        throw Exception("Invalid packet format: Missing start or end markers.");
      }
    } catch (e) {
      print("Error parsing packet: $e");
    }
  }

  void _processCompleteLogData() {
    // Log current index 순서대로 데이터 정렬 및 조합
    List<int> sortedKeys = _logParts.keys.toList()..sort();
    String completeLogData = sortedKeys.map((key) => _logParts[key]).join("\n");

    // 결과 출력
    print("Complete Log Data: \n$completeLogData");

    // 데이터 초기화
    _logParts.clear();
    _expectedLogCount = 0;
  }
}