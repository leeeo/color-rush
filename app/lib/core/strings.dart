import 'package:flutter/widgets.dart';

import '../game/game_logic.dart';

/// Minimal hand-rolled i18n (ko/en). For two locales and ~25 strings a full
/// gen_l10n pipeline is overkill; this keeps the build simple and fast.
class S {
  const S._({
    required this.appTitle,
    required this.tagline,
    required this.play,
    required this.best,
    required this.score,
    required this.tapToStart,
    required this.match,
    required this.noMatch,
    required this.gameOver,
    required this.newBest,
    required this.continueWithAd,
    required this.retry,
    required this.home,
    required this.removeAds,
    required this.restorePurchase,
    required this.adsRemoved,
    required this.purchaseThanks,
    required this.purchaseFailed,
    required this.storeUnavailable,
    required this.howToPlay,
    required this.howToPlayBody,
    required this.haptics,
    required this.colorNames,
    required this.adNotReady,
    required this.ok,
    required this.privacySettings,
  });

  final String appTitle;
  final String tagline;
  final String play;
  final String best;
  final String score;
  final String tapToStart;
  final String match;
  final String noMatch;
  final String gameOver;
  final String newBest;
  final String continueWithAd;
  final String retry;
  final String home;
  final String removeAds;
  final String restorePurchase;
  final String adsRemoved;
  final String purchaseThanks;
  final String purchaseFailed;
  final String storeUnavailable;
  final String howToPlay;
  final String howToPlayBody;
  final String haptics;
  final Map<GameColor, String> colorNames;
  final String adNotReady;
  final String ok;
  final String privacySettings;

  String colorName(GameColor c) => colorNames[c]!;

  static const S ko = S._(
    appTitle: 'Color Rush',
    tagline: '단어의 뜻과 글자 색이 같으면 ✓, 다르면 ✗!',
    play: '시작하기',
    best: '최고 기록',
    score: '점수',
    tapToStart: '탭해서 시작',
    match: '일치',
    noMatch: '불일치',
    gameOver: '게임 오버',
    newBest: '신기록!',
    continueWithAd: '광고 보고 이어하기',
    retry: '다시하기',
    home: '홈으로',
    removeAds: '광고 제거',
    restorePurchase: '구매 복원',
    adsRemoved: '광고 제거됨',
    purchaseThanks: '광고가 제거되었습니다. 감사합니다!',
    purchaseFailed: '구매를 완료하지 못했습니다.',
    storeUnavailable: '스토어에 연결할 수 없습니다.',
    howToPlay: '게임 방법',
    howToPlayBody: '화면에 색깔 단어가 나타납니다.\n\n'
        '단어의 "뜻"과 "글자 색"이 같으면 ✓(일치),\n다르면 ✗(불일치)를 누르세요.\n\n'
        '시간이 갈수록 빨라집니다. 최고 기록에 도전하세요!',
    haptics: '진동',
    colorNames: {
      GameColor.red: '빨강',
      GameColor.blue: '파랑',
      GameColor.green: '초록',
      GameColor.yellow: '노랑',
      GameColor.purple: '보라',
      GameColor.orange: '주황',
    },
    adNotReady: '광고를 아직 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
    ok: '확인',
    privacySettings: '광고 개인정보 설정',
  );

  static const S en = S._(
    appTitle: 'Color Rush',
    tagline: 'Tap ✓ if the word matches its ink color, ✗ if not!',
    play: 'PLAY',
    best: 'BEST',
    score: 'SCORE',
    tapToStart: 'TAP TO START',
    match: 'MATCH',
    noMatch: 'NO MATCH',
    gameOver: 'GAME OVER',
    newBest: 'NEW BEST!',
    continueWithAd: 'Watch ad to continue',
    retry: 'RETRY',
    home: 'HOME',
    removeAds: 'Remove ads',
    restorePurchase: 'Restore purchase',
    adsRemoved: 'Ads removed',
    purchaseThanks: 'Ads removed. Thank you!',
    purchaseFailed: 'Purchase could not be completed.',
    storeUnavailable: 'Store is unavailable.',
    howToPlay: 'How to play',
    howToPlayBody: 'A color word appears on screen.\n\n'
        'Tap ✓ (match) if the word\'s MEANING equals its INK COLOR,\n'
        'tap ✗ (no match) if it doesn\'t.\n\n'
        'It gets faster as you score. Beat your best!',
    haptics: 'Haptics',
    colorNames: {
      GameColor.red: 'RED',
      GameColor.blue: 'BLUE',
      GameColor.green: 'GREEN',
      GameColor.yellow: 'YELLOW',
      GameColor.purple: 'PURPLE',
      GameColor.orange: 'ORANGE',
    },
    adNotReady: 'Ad not loaded yet. Please try again in a moment.',
    ok: 'OK',
    privacySettings: 'Ad privacy settings',
  );

  static S of(BuildContext context) {
    final code = Localizations.maybeLocaleOf(context)?.languageCode;
    return code == 'ko' ? ko : en;
  }
}
