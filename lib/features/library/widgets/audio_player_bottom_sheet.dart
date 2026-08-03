import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/book_audio_model.dart';

/// Music-app-style player for audiobooks
class AudioPlayerBottomSheet extends StatefulWidget {
  final BookAudio audio;
  final VoidCallback? onFavoriteToggled;
  final VoidCallback? onDownloadToggled;

  const AudioPlayerBottomSheet({
    super.key,
    required this.audio,
    this.onFavoriteToggled,
    this.onDownloadToggled,
  });

  @override
  State<AudioPlayerBottomSheet> createState() => _AudioPlayerBottomSheetState();
}

class _AudioPlayerBottomSheetState extends State<AudioPlayerBottomSheet> {
  bool isPlaying = false;
  double currentPosition = 0.0;
  double playbackSpeed = 1.0;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.3,
      maxChildSize: 1,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: WakaColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              _buildDragHandle(),
              _buildAlbumArt(),
              _buildBookInfo(),
              _buildProgressBar(),
              _buildPlaybackControls(),
              _buildPlaybackSpeed(),
              _buildFavoriteAndDownload(),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: WakaColors.elevatedSoft,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Container(
          width: double.infinity,
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: WakaColors.surface,
            boxShadow: [
              BoxShadow(
                color: WakaColors.accent.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.headphones_outlined,
              size: 120,
              color: WakaColors.accent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            widget.audio.bookTitle,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: WakaColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.audio.narrator != null)
            Text(
              'Người đọc: ${widget.audio.narrator}',
              style: const TextStyle(
                color: WakaColors.mutedText,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final duration = widget.audio.duration?.inSeconds.toDouble() ?? 100.0;
    final position = currentPosition.clamp(0, duration);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: position.toDouble(),
              max: duration,
              activeColor: WakaColors.accent,
              inactiveColor: WakaColors.surface,
              onChanged: (value) {
                setState(() => currentPosition = value);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(Duration(seconds: position.toInt())),
                style: const TextStyle(
                  color: WakaColors.mutedText,
                  fontSize: 12,
                ),
              ),
              Text(
                _formatDuration(widget.audio.duration ?? const Duration()),
                style: const TextStyle(
                  color: WakaColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ControlButton(
            icon: Icons.skip_previous_rounded,
            onPressed: () {},
          ),
          _ControlButton(
            icon: Icons.replay_10_rounded,
            onPressed: () {
              setState(() => currentPosition = (currentPosition - 10).clamp(0, 100));
            },
            isSmall: true,
          ),
          GestureDetector(
            onTap: () => setState(() => isPlaying = !isPlaying),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 40,
                color: Colors.black,
              ),
            ),
          ),
          _ControlButton(
            icon: Icons.forward_30_rounded,
            onPressed: () {
              setState(() => currentPosition = currentPosition + 30);
            },
            isSmall: true,
          ),
          _ControlButton(
            icon: Icons.skip_next_rounded,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackSpeed() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tốc độ phát',
            style: TextStyle(
              color: WakaColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((speed) {
                final isSelected = speed == playbackSpeed;
                return GestureDetector(
                  onTap: () => setState(() => playbackSpeed = speed),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? WakaColors.accent : WakaColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${speed}x',
                      style: TextStyle(
                        color: isSelected ? Colors.black : WakaColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteAndDownload() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Favorite Button
          GestureDetector(
            onTap: () {
              setState(() => widget.audio.isFavorite = !widget.audio.isFavorite);
              widget.onFavoriteToggled?.call();
            },
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WakaColors.surface,
                  ),
                  child: Icon(
                    widget.audio.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: widget.audio.isFavorite ? WakaColors.danger : WakaColors.mutedText,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yêu thích',
                  style: TextStyle(
                    color: widget.audio.isFavorite ? WakaColors.accent : WakaColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Download Button
          GestureDetector(
            onTap: () {
              setState(() => widget.audio.isDownloaded = !widget.audio.isDownloaded);
              widget.onDownloadToggled?.call();
            },
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WakaColors.surface,
                  ),
                  child: Icon(
                    widget.audio.isDownloaded ? Icons.check_circle_rounded : Icons.download_rounded,
                    color: widget.audio.isDownloaded ? WakaColors.accent : WakaColors.mutedText,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.audio.isDownloaded ? 'Đã tải' : 'Tải xuống',
                  style: TextStyle(
                    color: widget.audio.isDownloaded ? WakaColors.accent : WakaColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isSmall;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isSmall ? 48 : 52,
        height: isSmall ? 48 : 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: WakaColors.surface,
        ),
        child: Icon(
          icon,
          color: WakaColors.accent,
          size: isSmall ? 22 : 26,
        ),
      ),
    );
  }
}
