import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import 'islamic_phrase_resolver.dart';

enum TranslationModelState {
  disabled,
  checkingModels,
  downloadingModels,
  ready,
  translating,
  error,
}

enum TranslationStatus { idle, preparingModels, translating, success, error }

class TranslationResult {
  const TranslationResult.success(this.arabicText, {this.isLocalMatch = false})
    : status = TranslationStatus.success,
      errorMessage = null;

  const TranslationResult.error(this.errorMessage)
    : arabicText = null,
      status = TranslationStatus.error,
      isLocalMatch = false;

  final TranslationStatus status;
  final String? arabicText;
  final String? errorMessage;
  final bool isLocalMatch;

  bool get isSuccess => status == TranslationStatus.success;
}

class ArabicNameTranslationService {
  OnDeviceTranslator? _translator;
  Future<bool>? _preparationFuture;

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<bool> checkModelStatus() async {
    if (!isSupportedPlatform) return false;
    try {
      final manager = OnDeviceTranslatorModelManager();
      final en = await manager
          .isModelDownloaded(TranslateLanguage.english.bcpCode)
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      final ar = await manager
          .isModelDownloaded(TranslateLanguage.arabic.bcpCode)
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      return en && ar;
    } on Object catch (e, st) {
      debugPrint('ML Kit checkModelStatus error: $e\n$st');
      return false;
    }
  }

  Future<bool> prepareModels({
    void Function(String message)? onProgress,
    bool force = false,
  }) async {
    if (!isSupportedPlatform) return false;
    if (!force && _preparationFuture != null) {
      return _preparationFuture!;
    }
    _preparationFuture = _internalPrepareModels(onProgress);
    return _preparationFuture!;
  }

  Future<bool> _internalPrepareModels(
    void Function(String message)? onProgress,
  ) async {
    final manager = OnDeviceTranslatorModelManager();

    try {
      final enDownloaded = await manager
          .isModelDownloaded(TranslateLanguage.english.bcpCode)
          .timeout(const Duration(seconds: 10), onTimeout: () => false);

      final arDownloaded = await manager
          .isModelDownloaded(TranslateLanguage.arabic.bcpCode)
          .timeout(const Duration(seconds: 10), onTimeout: () => false);

      if (enDownloaded && arDownloaded) {
        onProgress?.call('Offline Arabic translation ready');
        return true;
      }

      onProgress?.call('Downloading offline Arabic translation…');

      var success = true;

      if (!enDownloaded) {
        final enRes = await manager
            .downloadModel(
              TranslateLanguage.english.bcpCode,
              isWifiRequired: false,
            )
            .timeout(const Duration(seconds: 90), onTimeout: () => false);
        if (!enRes) success = false;
      }

      if (!arDownloaded) {
        final arRes = await manager
            .downloadModel(
              TranslateLanguage.arabic.bcpCode,
              isWifiRequired: false,
            )
            .timeout(const Duration(seconds: 90), onTimeout: () => false);
        if (!arRes) success = false;
      }

      if (success) {
        onProgress?.call('Offline Arabic translation ready');
      } else {
        onProgress?.call('Translation model unavailable');
      }

      return success;
    } on Object catch (e, st) {
      debugPrint('ML Kit Model preparation error: $e\n$st');
      onProgress?.call('Translation model unavailable');
      return false;
    }
  }

  Future<TranslationResult> translate(
    String text, {
    void Function(String message)? onProgress,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const TranslationResult.error('Empty text');
    }

    // 1. Check local Islamic phrase resolver first
    final localMatch = IslamicPhraseResolver.resolve(trimmed);
    if (localMatch != null) {
      return TranslationResult.success(localMatch, isLocalMatch: true);
    }

    if (!isSupportedPlatform) {
      return const TranslationResult.error(
        'Translation unavailable. Enter Arabic manually or retry.',
      );
    }

    // 2. Prepare models if missing
    try {
      final prepSuccess = await prepareModels(onProgress: onProgress);
      if (!prepSuccess) {
        _preparationFuture = null;
        return const TranslationResult.error(
          'Translation unavailable. Enter Arabic manually or retry.',
        );
      }
    } on Object catch (e, st) {
      _preparationFuture = null;
      debugPrint('ML Kit Model preparation error: $e\n$st');
      return const TranslationResult.error(
        'Translation unavailable. Enter Arabic manually or retry.',
      );
    }

    // 3. Perform ML Kit translation with timeout
    try {
      _translator ??= OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: TranslateLanguage.arabic,
      );

      final translated = await _translator!
          .translateText(trimmed)
          .timeout(const Duration(seconds: 90));

      final resultText = translated.trim();
      if (resultText.isEmpty) {
        return const TranslationResult.error(
          'Translation unavailable. Enter Arabic manually or retry.',
        );
      }

      return TranslationResult.success(resultText);
    } on Object catch (e, st) {
      debugPrint('ML Kit Translation error: $e\n$st');
      return const TranslationResult.error(
        'Translation unavailable. Enter Arabic manually or retry.',
      );
    }
  }

  void dispose() {
    _translator?.close();
    _translator = null;
    _preparationFuture = null;
  }
}

final arabicTranslationServiceProvider = Provider<ArabicNameTranslationService>(
  (ref) {
    final service = ArabicNameTranslationService();
    ref.onDispose(service.dispose);
    return service;
  },
);
