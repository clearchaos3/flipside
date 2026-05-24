import Foundation
import AVFoundation

/// Audio file decoding into PCM buffers, cached so repeated triggers don't
/// re-decode. Compressed formats (mp3, m4a, flac, ogg) take real time to
/// decode; pads get a single decode-on-load.
public enum SampleLoader {

    public static let supportedExtensions: Set<String> = [
        "wav", "aif", "aiff", "mp3", "m4a", "flac", "ogg", "snd", "s1s", "s3s"
    ]

    public static func isSupported(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    /// Decode an audio file into an in-memory PCM buffer.
    /// Synchronous — callers that care about main-thread responsiveness
    /// should dispatch to a background queue.
    public static func load(url: URL) throws -> AVAudioPCMBuffer {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(file.length)
        ) else {
            throw NSError(domain: "mac-mpc.SampleLoader", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not allocate PCM buffer"])
        }
        try file.read(into: buffer)
        return buffer
    }
}
