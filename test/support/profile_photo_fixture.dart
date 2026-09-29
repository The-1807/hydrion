import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

Future<Uint8List> syntheticPng(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawPaint(ui.Paint()..color = const ui.Color(0xff14783f));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

Uint8List paddedPng(Uint8List png, int length) {
  final count = length - png.length - 12;
  final chunk = Uint8List(count + 12);
  ByteData.sublistView(chunk).setUint32(0, count);
  chunk.setRange(4, 8, ascii.encode('npAd'));
  var crc = 0xffffffff;
  for (var i = 4; i < count + 8; i++) {
    crc ^= chunk[i];
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xedb88320 : 0);
    }
  }
  ByteData.sublistView(chunk).setUint32(count + 8, crc ^ 0xffffffff);
  return Uint8List.fromList(
      [...png.take(png.length - 12), ...chunk, ...png.skip(png.length - 12)]);
}
