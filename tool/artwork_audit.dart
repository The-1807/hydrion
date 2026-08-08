import 'dart:io';
import 'dart:typed_data';

const _artworkDirectory = 'assets/images/challenges';
const _transparentArtwork = 'shift_hydration_check.png';

void main() {
  final directory = Directory(_artworkDirectory);
  if (!directory.existsSync()) {
    stderr.writeln('Missing challenge artwork directory: $_artworkDirectory');
    exitCode = 1;
    return;
  }

  final files = directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.png'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final filesByLength = <int, List<File>>{};
  for (final file in files) {
    filesByLength.putIfAbsent(file.lengthSync(), () => <File>[]).add(file);
  }
  for (final sameLength
      in filesByLength.values.where((group) => group.length > 1)) {
    for (var left = 0; left < sameLength.length; left++) {
      final leftBytes = sameLength[left].readAsBytesSync();
      for (var right = left + 1; right < sameLength.length; right++) {
        final rightBytes = sameLength[right].readAsBytesSync();
        if (_matches(rightBytes, 0, leftBytes)) {
          stderr.writeln(
            'Duplicate challenge artwork: ${sameLength[left].path} and ${sameLength[right].path}',
          );
          exitCode = 1;
        }
      }
    }
  }

  final shiftFile = File('$_artworkDirectory/$_transparentArtwork');
  if (!shiftFile.existsSync() ||
      !_hasAlphaChannel(shiftFile.readAsBytesSync())) {
    stderr.writeln(
        '$_transparentArtwork must contain genuine transparent pixels.');
    exitCode = 1;
  }
  if (exitCode == 0) {
    stdout.writeln(
        'Artwork audit passed for ${files.length} challenge PNG files.');
  }
}

bool _hasAlphaChannel(Uint8List png) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (png.length < 33 || !_matches(png, 0, signature)) return false;
  final ihdrLength = _u32(png, 8);
  final isIhdr = String.fromCharCodes(png.sublist(12, 16)) == 'IHDR';
  final bitDepth = png[24];
  final colorType = png[25];
  return ihdrLength == 13 && isIhdr && bitDepth == 8 && colorType == 6;
}

int _u32(Uint8List bytes, int offset) =>
    ByteData.sublistView(bytes).getUint32(offset, Endian.big);

bool _matches(Uint8List bytes, int offset, List<int> expected) {
  for (var i = 0; i < expected.length; i++) {
    if (bytes[offset + i] != expected[i]) return false;
  }
  return true;
}
