import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:video_player/video_player.dart';

import 'package:reservation_workshop/core/widgets/app_card.dart';

import '../../data/models/job_order_media_model.dart';

class JobOrderAttachmentsWidget extends StatefulWidget {
  const JobOrderAttachmentsWidget({super.key, required this.media});

  final List<JobOrderMediaModel> media;

  @override
  State<JobOrderAttachmentsWidget> createState() =>
      _JobOrderAttachmentsWidgetState();
}

class _JobOrderAttachmentsWidgetState extends State<JobOrderAttachmentsWidget> {
  String? _activeTag;
  int _selectedIndex = 0;

  List<String> get _tags {
    final seen = <String>{};
    final tags = <String>[];
    for (final m in widget.media) {
      final t = m.tag;
      if (t != null && seen.add(t)) tags.add(t);
    }
    return tags;
  }

  List<JobOrderMediaModel> get _filtered => _activeTag == null
      ? widget.media
      : widget.media.where((m) => m.tag == _activeTag).toList();

  void _openVideo(String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Positioned.fill(child: _VideoPlayerView(url: url)),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openImagePreview(JobOrderMediaModel item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                child: Center(
                  child: Image.network(
                    item.url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb(JobOrderMediaModel item, {required bool selected}) {
    return GestureDetector(
      onTap: () {
        if (item.isVideo) {
          _openVideo(item.url);
          return;
        }
        setState(() => _selectedIndex = _filtered.indexOf(item));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFFD4AF37) : const Color(0xFF2A2A2A),
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: item.isVideo
            ? Container(
                color: const Color(0xFF111111),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              )
            : Image.network(
                item.url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF111111),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 22,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) return const SizedBox.shrink();

    final filtered = _filtered;
    if (filtered.isEmpty) return const SizedBox.shrink();
    if (_selectedIndex >= filtered.length) _selectedIndex = 0;
    final selected = filtered[_selectedIndex];
    final tags = _tags;

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      backgroundColor: const Color(0xFF050505),
      borderColor: const Color(0xFF0A0A0A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'job_order.attachments.title'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _tagChip(
                  label: 'job_order.attachments.all'.tr(),
                  selected: _activeTag == null,
                  onTap: () => setState(() {
                    _activeTag = null;
                    _selectedIndex = 0;
                  }),
                ),
                ...tags.map(
                  (t) => _tagChip(
                    label: t,
                    selected: _activeTag == t,
                    onTap: () => setState(() {
                      _activeTag = t;
                      _selectedIndex = 0;
                    }),
                  ),
                ),
              ],
            )
          else
            _tagChip(
              label: 'job_order.attachments.all'.tr(),
              selected: true,
              onTap: () {},
            ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              if (selected.isVideo) {
                _openVideo(selected.url);
              } else {
                _openImagePreview(selected);
              }
            },
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                clipBehavior: Clip.antiAlias,
                child: selected.isVideo
                    ? const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 56,
                        ),
                      )
                    : Image.network(
                        selected.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 48,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Text(
              selected.tag ?? 'job_order.attachments.no_tag'.tr(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, i) =>
                _thumb(filtered[i], selected: i == _selectedIndex),
          ),
        ],
      ),
    );
  }

  Widget _tagChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD4AF37) : const Color(0xFF111111),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFD4AF37) : const Color(0xFF2A2A2A),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _VideoPlayerView extends StatefulWidget {
  const _VideoPlayerView({required this.url});

  final String url;

  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() => _ready = true);
            _controller.play();
          })
          .catchError((_) {
            if (!mounted) return;
            setState(() => _failed = true);
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Icon(Icons.error_outline, color: Colors.white54, size: 48),
      );
    }
    if (!_ready) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      );
    }
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    if (!_controller.value.isPlaying)
                      const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white70,
                        size: 64,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        VideoProgressIndicator(
          _controller,
          allowScrubbing: true,
          colors: const VideoProgressColors(
            playedColor: Color(0xFFD4AF37),
            bufferedColor: Colors.white24,
            backgroundColor: Colors.white12,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
      ],
    );
  }
}
