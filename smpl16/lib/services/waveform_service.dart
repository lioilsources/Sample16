import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

class WaveformService {
  static const int waveformPoints = 256;

  /// Extracts a downsampled waveform from a WAV file.
  /// Returns null if the file is not a valid WAV.
  static Future<Float32List?> extractFromWav(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return _parseWav(bytes);
    } catch (_) {
      return null;
    }
  }

  static Float32List? _parseWav(Uint8List bytes) {
    if (bytes.length < 44) return null;
    final view = ByteData.sublistView(bytes);

    // Verify RIFF/WAVE header
    if (bytes[0] != 0x52 || bytes[1] != 0x49 ||
        bytes[2] != 0x46 || bytes[3] != 0x46) {
      return null;
    }
    if (bytes[8] != 0x57 || bytes[9] != 0x41 ||
        bytes[10] != 0x56 || bytes[11] != 0x45) {
      return null;
    }

    int offset = 12;
    int dataOffset = -1;
    int dataSize = 0;
    int bitsPerSample = 16;
    int numChannels = 1;

    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = view.getUint32(offset + 4, Endian.little);

      if (chunkId == 'fmt ') {
        numChannels = view.getUint16(offset + 10, Endian.little);
        bitsPerSample = view.getUint16(offset + 22, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = offset + 8;
        dataSize = chunkSize;
        break;
      }
      offset += 8 + chunkSize;
    }

    if (dataOffset < 0 || dataSize == 0) return null;

    final bytesPerSample = bitsPerSample ~/ 8;
    final totalSamples = dataSize ~/ (bytesPerSample * numChannels);
    if (totalSamples == 0) return null;

    final blockSize = math.max(1, totalSamples ~/ waveformPoints);
    final result = Float32List(waveformPoints);

    for (int i = 0; i < waveformPoints; i++) {
      double maxAmp = 0.0;
      for (int j = 0; j < blockSize; j++) {
        final sampleIdx = (i * blockSize + j) * bytesPerSample * numChannels;
        final byteIdx = dataOffset + sampleIdx;
        if (byteIdx + bytesPerSample > bytes.length) break;

        double sample;
        if (bitsPerSample == 16) {
          sample = view.getInt16(byteIdx, Endian.little).abs() / 32768.0;
        } else if (bitsPerSample == 24) {
          final lo = bytes[byteIdx];
          final mid = bytes[byteIdx + 1];
          final hi = bytes[byteIdx + 2];
          int val = lo | (mid << 8) | (hi << 16);
          if (val & 0x800000 != 0) val -= 0x1000000;
          sample = val.abs() / 8388608.0;
        } else if (bitsPerSample == 32) {
          sample = view.getInt32(byteIdx, Endian.little).abs() / 2147483648.0;
        } else {
          sample = (view.getUint8(byteIdx) - 128).abs() / 128.0;
        }

        if (sample > maxAmp) maxAmp = sample;
      }
      result[i] = maxAmp;
    }
    return result;
  }

  /// Returns a fake random waveform for non-WAV files (e.g. imported M4A).
  static Float32List generateFake() {
    final rng = math.Random();
    final result = Float32List(waveformPoints);
    double prev = 0.3;
    for (int i = 0; i < waveformPoints; i++) {
      prev = (prev + (rng.nextDouble() - 0.5) * 0.3).clamp(0.05, 0.95);
      result[i] = prev;
    }
    return result;
  }
}
