/// Model for book audio content
class BookAudio {
  final String id;
  final String bookTitle;
  final String? audioUrl;
  final Duration? duration;
  final String? narrator;
  bool isFavorite;
  bool isDownloaded;

  BookAudio({
    required this.id,
    required this.bookTitle,
    this.audioUrl,
    this.duration,
    this.narrator,
    this.isFavorite = false,
    this.isDownloaded = false,
  });

  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
}
