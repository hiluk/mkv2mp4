import 'dart:io';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../busy.dart';
import '../rust/api/shorts.dart';
import '../shorts/models.dart';
import '../shorts/shorts.dart';
import 'kit/controls.dart';
import 'kit/palette.dart';
import 'widgets.dart';

/// Режим «Ролики для TikTok»: нарезка 9:16 с субтитрами из файла или распознанной речью.
class ShortsPage extends ConsumerWidget {
  const ShortsPage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref, List<String> paths) async {
    final added = await ref.read(shortsProvider.notifier).addPaths(paths);
    if (added == 0 && context.mounted) showNothingFound(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(shortsProvider.select((s) => s.jobs));
    final running = ref.watch(shortsProvider.select((s) => s.running));
    Future<void> pick() async {
      final files = await pickVideoFiles();
      if (files.isNotEmpty && context.mounted) await _add(context, ref, files);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FileDropZone(
            enabled: !running,
            hint: 'Перетащите сюда видео:\nтекст возьмётся из субтитров или из речи',
            onTap: pick,
            onPaths: (p) => _add(context, ref, p),
            child: jobs.isEmpty
                ? null
                : FileList(
                    count: jobs.length,
                    itemBuilder: (_, i) => _ShortsRow(job: jobs[i]),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        const _Settings(),
        const SizedBox(height: 12),
        _Actions(onAdd: pick),
      ],
    );
  }
}

String _duration(double secs) {
  final s = secs.round();
  final h = s ~/ 3600, m = s ~/ 60 % 60, sec = s % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '$m:${two(sec)}';
}

String _trackLabel(TrackInfo t, {bool subtitle = false}) {
  final parts = [
    '#${t.index + 1}',
    if (t.language != null) t.language!,
    if (t.title != null) t.title!,
  ];
  final suffix = subtitle && !t.isText ? ' (картинки)' : ' (${t.codec})';
  return parts.join(' · ') + suffix;
}

class _ShortsRow extends ConsumerWidget {
  const _ShortsRow({required this.job});

  final ShortsJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = ref.watch(shortsProvider.select((s) => s.running));
    final notifier = ref.read(shortsProvider.notifier);
    final info = job.info;
    final editable =
        !running && (job.status == ShortsStatus.ready || job.isFinished) && job.hasSource;

    final (icon, tone) = switch (job.status) {
      ShortsStatus.loading => (CupertinoIcons.hourglass, BadgeTone.neutral),
      ShortsStatus.ready => (CupertinoIcons.clock, BadgeTone.neutral),
      ShortsStatus.running => (CupertinoIcons.scissors, BadgeTone.accent),
      ShortsStatus.done => (CupertinoIcons.checkmark_alt, BadgeTone.ok),
      ShortsStatus.cancelled => (CupertinoIcons.xmark, BadgeTone.neutral),
      ShortsStatus.error => (CupertinoIcons.exclamationmark, BadgeTone.error),
    };
    final isRunning = job.status == ShortsStatus.running;

    return FileRow(
      badge: StatusBadge(icon: icon, tone: tone),
      name: job.name,
      detail: info == null ? null : _duration(info.duration),
      controls: info != null && (info.subtitles.isNotEmpty || info.audio.isNotEmpty)
          ? Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Tooltip(
                  message: 'Откуда взять текст',
                  child: KitSelect<int>(
                    icon: CupertinoIcons.captions_bubble,
                    value: job.speech ? Shorts.speechTrack : job.subtitleTrack,
                    placeholder: 'нет текстовых субтитров',
                    items: [
                      for (final t in info.subtitles)
                        SelectItem(t.index, _trackLabel(t, subtitle: true), enabled: t.isText),
                      if (info.audio.isNotEmpty)
                        const SelectItem(
                          Shorts.speechTrack,
                          'Распознать речь (Whisper + Claude Haiku)',
                        ),
                    ],
                    onChanged: editable ? (v) => notifier.setSubtitleTrack(job.input, v) : null,
                  ),
                ),
                if (info.audio.length > 1)
                  Tooltip(
                    message: 'Звук',
                    child: KitSelect<int>(
                      icon: CupertinoIcons.speaker_2,
                      value: job.audioTrack,
                      items: [for (final t in info.audio) SelectItem(t.index, _trackLabel(t))],
                      onChanged: editable ? (v) => notifier.setAudioTrack(job.input, v) : null,
                    ),
                  ),
              ],
            )
          : null,
      progress: isRunning ? job.progress : null,
      status: isRunning
          ? [
              '${(job.progress * 100).round()}%',
              if (job.message.isNotEmpty) job.message,
            ].join(' · ')
          : job.message,
      statusTone: tone,
      warning: job.warning,
      action: switch (job.status) {
        ShortsStatus.done => KitIconButton(
          tooltip: 'Открыть папку с роликами',
          icon: CupertinoIcons.folder,
          onPressed: () => revealInFinder(job.outputDir!),
        ),
        ShortsStatus.error || ShortsStatus.cancelled when job.hasSource => KitIconButton(
          tooltip: 'Повторить',
          icon: CupertinoIcons.arrow_clockwise,
          onPressed: running ? null : () => notifier.retry(job.input),
        ),
        ShortsStatus.running => null,
        _ => KitIconButton(
          tooltip: 'Убрать',
          icon: CupertinoIcons.xmark,
          onPressed: running ? null : () => notifier.remove(job.input),
        ),
      },
    );
  }
}

class _Settings extends ConsumerWidget {
  const _Settings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final settings = ref.watch(shortsProvider.select((s) => s.settings));
    final running = ref.watch(shortsProvider.select((s) => s.running));
    final notifier = ref.read(shortsProvider.notifier);

    return SettingsBar(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FieldLabel('Нарезка:'),
            const SizedBox(width: 6),
            Tooltip(
              message:
                  'Лучшие моменты выбирает Claude Haiku по расшифровке; '
                  'ролики по 60–180 с. Нужен ключ в .env.',
              child: KitSelect<bool>(
                value: settings.bestMoments,
                onChanged: running ? null : notifier.setBestMoments,
                items: const [
                  SelectItem(false, 'всё видео подряд'),
                  SelectItem(true, 'лучшие моменты'),
                ],
              ),
            ),
          ],
        ),
        if (settings.bestMoments)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FieldLabel('Длина:'),
              const SizedBox(width: 6),
              Text(
                '60–180 с',
                style: TextStyle(fontSize: 13, color: p.text, fontWeight: FontWeight.w500),
              ),
            ],
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FieldLabel('Длина:'),
              const SizedBox(width: 6),
              SizedBox(
                width: 64,
                child: Text(
                  'до ${settings.maxLen} с',
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 13,
                    color: p.text,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              SizedBox(
                width: 150,
                child: Slider(
                  value: settings.maxLen.toDouble(),
                  min: 15,
                  max: 180,
                  divisions: 33,
                  onChanged: running ? null : (v) => notifier.setMaxLen(v.round()),
                ),
              ),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FieldLabel('Текст:'),
            const SizedBox(width: 6),
            KitSelect<CaptionStyle>(
              value: settings.captions,
              onChanged: running ? null : notifier.setCaptions,
              items: const [
                SelectItem(CaptionStyle.revealHighlight, 'по мере речи + подсветка'),
                SelectItem(CaptionStyle.reveal, 'по мере речи'),
                SelectItem(CaptionStyle.highlight, 'подсветка слова'),
                SelectItem(CaptionStyle.whole, 'реплика целиком'),
              ],
            ),
          ],
        ),
        OutDirPicker(outDir: settings.outDir, enabled: !running, onChanged: notifier.setOutDir),
        const _SpeechStatus(),
      ],
    );
  }
}

/// Есть ли ключ Claude для вычитки распознанного текста; кнопка открывает .env.
class _SpeechStatus extends ConsumerWidget {
  const _SpeechStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final config = ref.watch(speechConfigProvider);
    return switch (config) {
      AsyncData(:final value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: value.hasApiKey ? p.ok : p.warn,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            value.hasApiKey ? 'Claude: ключ задан' : 'Claude: нет ключа, речь без вычитки',
            style: TextStyle(fontSize: 12.5, color: p.muted),
          ),
          if (!value.whisperAvailable)
            Text('  · whisper-cli не найден', style: TextStyle(fontSize: 12.5, color: p.error)),
          const SizedBox(width: 2),
          KitButton.text(
            label: 'Открыть .env',
            onPressed: () => Process.run('open', ['-t', value.envFile]),
          ),
          KitIconButton(
            tooltip: 'Перечитать .env',
            icon: CupertinoIcons.arrow_clockwise,
            onPressed: () => ref.invalidate(speechConfigProvider),
          ),
        ],
      ),
      AsyncError(:final error) => Text(
        '.env: $error',
        style: TextStyle(fontSize: 12.5, color: p.error),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shortsProvider);
    final busy = ref.watch(busyProvider);
    final notifier = ref.read(shortsProvider.notifier);
    return Row(
      children: [
        KitButton(
          icon: CupertinoIcons.plus,
          label: 'Добавить файлы',
          onPressed: state.running ? null : onAdd,
        ),
        const SizedBox(width: 6),
        if (state.jobs.isNotEmpty)
          KitButton.text(
            label: 'Очистить готовые',
            onPressed: state.running ? null : notifier.clearFinished,
          ),
        const Spacer(),
        if (state.running)
          KitButton(icon: CupertinoIcons.stop_fill, label: 'Отменить', onPressed: notifier.cancel)
        else
          KitButton.primary(
            icon: CupertinoIcons.scissors,
            label: 'Нарезать',
            onPressed: state.hasReady && !busy ? notifier.start : null,
          ),
      ],
    );
  }
}
