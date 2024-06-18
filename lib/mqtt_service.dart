import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final MqttServerClient client = MqttServerClient(
      '2b31fd28e0714e119cc1d685f8da3c53.s1.eu.hivemq.cloud', '');

  void connect(
      Function(String topic, String payload, String timestamp)
          onMessageReceived) async {
    client.port = 8883;
    client.secure = true;
    client.setProtocolV311();
    client.logging(on: true);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('')
        .authenticateAs('admin', 'Sethur2006@')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
      return;
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT client connected');
    } else {
      print(
          'ERROR: MQTT client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
      client.disconnect();
      return;
    }

    const topics = ['volt', 'rps', 'freq', 'temp', 'health'];
    topics.forEach((topic) {
      client.subscribe(topic, MqttQos.atMostOnce);
    });

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);
      final timestamp = DateTime.now().toString();
      onMessageReceived(c[0].topic, payload, timestamp);
    });

    client.onDisconnected = () {
      print('MQTT client disconnected');
    };

    client.pongCallback = () {
      print('Ping response client callback invoked');
    };
  }

  void disconnect() {
    client.disconnect();
  }
}
