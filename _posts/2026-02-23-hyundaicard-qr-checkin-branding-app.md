---
layout: post
title: "QR 체크인 + 브랜딩 앱을 반복 생산 가능한 형태로 만든 방법"
date: 2026-02-16 20:00:00 +0900
categories: [300-project]
tags: [qr, checkin, branding, white-label, frontend]
description: "현대카드 계열 이벤트 도메인에서 QR 체크인과 브랜딩 앱을 빠르고 안전하게 반복 출시하기 위해 정리한 구조."
---

이벤트 프로젝트를 몇 번 겪다 보면 패턴이 보인다.

- 일정은 짧고
- 브랜드 요구는 다르고
- 실패 허용치는 거의 없다.

그래서 프로젝트마다 새로 만들기보다,
반복 가능한 공통 코어를 먼저 잡았다.

---

이번에 고정한 코어는 두 개였다.

1) 체크인 상태 머신

- 미체크인
- 유효 검증 중
- 체크인 완료
- 중복/만료/오류

2) 브랜딩 주입 레이어

- 색상/타이포/에셋/카피를 설정으로 분리
- 핵심 플로우 코드는 수정 없이 재사용

---

이 구조의 장점은 단순하다.

브랜드마다 화면은 다르게 보여도,
체크인 신뢰도는 동일하게 유지할 수 있다.

프로젝트를 "작품"처럼 만들면 멋있다.
하지만 운영에서는 "플랫폼"처럼 만드는 쪽이 오래 간다.

## 현장 안정성을 높이기 위해 추가로 잡은 기준

이 프로젝트에서 제일 빨리 깨지는 건 화면이 아니라 체크인 신뢰도였다. 한 번의 중복 인식, 한 번의 네트워크 끊김, 한 번의 타임아웃이 현장 운영팀 입장에서는 "입장 동선 붕괴"로 이어진다. 그래서 QR 도메인에서는 인식 정확도보다 **상태 전이의 보수성**을 높였다.

먼저 스캔 단계는 단일 엔진에 의존하지 않았다. 웹뷰에서 가능한 경우에는 브라우저 기반 인식 경로를 쓰되([Shape Detection API 제안](https://wicg.github.io/shape-detection-api/)), 기기 편차가 큰 지점에서는 네이티브 측 검증 경로를 우선 사용하도록 분리했다. 안드로이드 단말은 [ML Kit Barcode Scanning](https://developers.google.com/ml-kit/vision/barcode-scanning)과 디바이스 카메라 상태를 같이 보고, 실패가 연속될 때는 즉시 수동 입력 경로를 열었다. "한 번 더 스캔해보세요"를 반복시키는 대신 실패를 운영 가능한 경로로 전환한 것이다.

체크인 확정 API는 결제 도메인에서 쓰는 패턴을 그대로 가져와 멱등 처리 원칙을 적용했다. HTTP에서 멱등성 개념 자체는 [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110#section-9.2.2)에 정의돼 있지만, 실제 운영에서는 요청 재전송이 당연히 발생하므로 애플리케이션 레벨에서 idempotency key를 추가로 강제해야 했다. 이 부분은 [Stripe의 idempotency 가이드](https://docs.stripe.com/api/idempotent_requests)를 참고해 재시도 시 동일 결과를 보장하도록 맞췄다.

브랜딩은 별개로, 체크인 코어를 침범하지 못하게 경계를 분리했다. 색상/카피/에셋은 런타임 토큰으로 바꾸되([Design Tokens Community Group](https://www.designtokens.org/), [Format Module](https://tr.designtokens.org/format/)), 체크인 상태머신과 에러 정책은 공통 코어로 고정했다. 이 구분 덕분에 브랜드마다 화면이 달라도 운영 정책은 동일하게 유지됐다.

마지막으로 웹뷰 업데이트 반영 지연을 고려해, 구버전 앱에서도 서버 플래그만으로 체크인 경로를 안전하게 우회할 수 있게 했다. 웹뷰 자체 제약은 [Android WebView](https://developer.android.com/reference/android/webkit/WebView), [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview) 문서를 기준으로 기능 가용 범위를 분리해 두었다. 결국 현장에서는 완벽한 기술보다, 실패를 예측하고 줄이는 운영 설계가 더 큰 차이를 만들었다.

## 참고자료
- [Google ML Kit: Barcode Scanning](https://developers.google.com/ml-kit/vision/barcode-scanning)
- [ZXing API Docs](https://zxing.github.io/zxing/apidocs/)
- [Shape Detection API (WICG)](https://wicg.github.io/shape-detection-api/)
- [RFC 9110 - Idempotent Methods](https://www.rfc-editor.org/rfc/rfc9110#section-9.2.2)
- [Stripe API - Idempotent requests](https://docs.stripe.com/api/idempotent_requests)
- [Design Tokens Community Group](https://www.designtokens.org/)
- [Design Tokens Format Module](https://tr.designtokens.org/format/)
- [Android WebView Reference](https://developer.android.com/reference/android/webkit/WebView)
- [Apple WKWebView Documentation](https://developer.apple.com/documentation/webkit/wkwebview)

## 브랜딩 앱을 운영하면서 더 중요해진 기준

프로젝트 초기에는 "브랜드별 요구를 얼마나 빨리 반영하느냐"가 핵심처럼 보였다. 시간이 지나면서는 생각이 달라졌다. 빠른 반영도 중요하지만, 브랜드가 늘어도 체크인 신뢰도가 흔들리지 않는 것이 훨씬 중요했다.

특히 현장 이벤트에서는 작은 지연이나 오인식도 즉시 민원으로 이어진다. 그래서 저는 시각적 커스터마이징보다 운영 일관성을 우선순위에 두게 됐다. 브랜드마다 화면이 달라도, 실패 시 안내 문구의 구조와 복구 행동은 동일하게 유지하려고 했다. 이 기준 덕분에 운영팀 교육 비용도 줄었다.

제가 반성했던 지점은, 초기에는 커스터마이징 요청을 대부분 개발 이슈로만 처리한 것이다. 실제로는 디자인/운영/기획의 합의가 먼저 필요한 경우가 많았다. 이후에는 요청 접수 단계에서 기술 가능성뿐 아니라 운영 영향까지 함께 검토하도록 프로세스를 바꿨다.

## 다음 확장을 위해 남겨둔 원칙

- 브랜드 확장 시 코어 플로우 변경은 원칙적으로 금지
- 신규 테마 적용 전 체크인 실패 시나리오 먼저 검증
- 매장/이벤트 유형별 fallback 경로 사전 준비
- 운영팀과 공통 용어집 유지(체크인 상태 명칭 통일)
- 이벤트 종료 후 반드시 간단 회고 진행

저는 이 구조가 이미 충분하다고 생각하지 않는다. 다만 "브랜딩 다양성"과 "운영 안정성"을 동시에 지키려면, 코어를 보호하는 원칙이 흔들리지 않아야 한다는 점은 더 확신하게 됐다.
