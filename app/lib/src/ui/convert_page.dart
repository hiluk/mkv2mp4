import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../busy.dart';
import '../converter/converter.dart';
import '../converter/models.dart';
import 'kit/controls.dart';
import 'widgets.dart';

/// Режим «Конвертация в MP4».
class ConvertPage extends ConsumerWidget {
  const ConvertPage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref, List<String> paths) async {
    final added = await ref.read(converterProvider.notifier).addPaths(paths);
    if (added == 0 && context.mounted) showNothingFound(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(converterProvider.select((s) => s.jobs));
    final running = ref.watch(converterProvider.select((s) => s.running));
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
            hint: 'Перетащите сюда видео или папки',
            onTap: pick,
            onPaths: (p) => _add(context, ref, p),
            child: jobs.isEmpty
                ? null
                : FileList(count: jobs.length, itemBuilder: (_, i) => _JobRow(job: jobs[i])),
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

class _JobRow extends ConsumerWidget {
  const _JobRow({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = ref.watch(converterProvider.select((s) => s.running));
    final notifier = ref.read(converterProvider.notifier);
    final (icon, tone) = switch (job.status) {
      JobStatus.waiting => (CupertinoIcons.clock, BadgeTone.neutral),
      JobStatus.running => (CupertinoIcons.arrow_2_squarepath, BadgeTone.accent),
      JobStatus.done => (CupertinoIcons.checkmark_alt, BadgeTone.ok),
      JobStatus.skipped => (CupertinoIcons.forward, BadgeTone.neutral),
      JobStatus.cancelled => (CupertinoIcons.xmark, BadgeTone.neutral),
      JobStatus.error => (CupertinoIcons.exclamationmark, BadgeTone.error),
    };
    final isRunning = job.status == JobStatus.running;
    return FileRow(
      badge: StatusBadge(icon: icon, tone: tone),
      name: job.name,
      progress: isRunning ? job.progress : null,
      status: isRunning
          ? [
              '${(job.progress * 100).round()}%',
              if (job.message.isNotEmpty) job.message,
            ].join(' · ')
          : job.message,
      statusTone: tone,
      action: switch (job.status) {
        JobStatus.done || JobStatus.skipped => KitIconButton(
            tooltip: 'Показать в Finder',
            icon: CupertinoIcons.folder,
            onPressed: () => revealInFinder(job.output!),
          ),
        JobStatus.error || JobStatus.cancelled => KitIconButton(
            tooltip: 'Повторить',
            icon: CupertinoIcons.arrow_clockwise,
            onPressed: running ? null : () => notifier.retry(job.input),
          ),
        JobStatus.waiting => KitIconButton(
            tooltip: 'Убрать',
            icon: CupertinoIcons.xmark,
            onPressed: () => notifier.remove(job.input),
          ),
        JobStatus.running => null,
      },
    );
  }
}

class _Settings extends ConsumerWidget {
  const _Settings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(converterProvider.select((s) => s.settings));
    final running = ref.watch(converterProvider.select((s) => s.running));
    final notifier = ref.read(converterProvider.notifier);

    return SettingsBar(
      children: [
        LabeledSwitch(
          label: 'Полное перекодирование',
          tooltip: 'Медленно. Нужно, только если MP4 не открывается '
              'на старом устройстве.',
          value: settings.reencode,
          onChanged: running ? null : notifier.setReencode,
        ),
        LabeledSwitch(
          label: 'Перезаписывать MP4',
          value: settings.overwrite,
          onChanged: running ? null : notifier.setOverwrite,
        ),
        OutDirPicker(
          outDir: settings.outDir,
          enabled: !running,
          onChanged: notifier.setOutDir,
        ),
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(converterProvider);
    final busy = ref.watch(busyProvider);
    final notifier = ref.read(converterProvider.notifier);
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
          KitButton(
            icon: CupertinoIcons.stop_fill,
            label: 'Отменить',
            onPressed: notifier.cancel,
          )
        else
          KitButton.primary(
            label: 'Конвертировать',
            onPressed: state.hasWaiting && !busy ? notifier.start : null,
          ),
      ],
    );
  }
}
