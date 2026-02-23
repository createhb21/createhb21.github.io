---
layout: post
title: "배포를 ‘버튼 클릭’이 아니라 ‘복구 가능한 절차’로 설계하기"
date: 2026-02-16 22:20:00 +0900
categories: [400-area]
tags: [devops, deployment, rollback, kiosk, webview, semver]
description: "CI/CD, 버저닝, 브라우저 타겟, 하이브리드 리로드, 롤백까지 배포 안정성을 만드는 실전 관점을 정리했다."
---

속도와 안정성은 보통 트레이드오프로 말해진다.
실무에선 둘 다 못 잡으면 곧 팀 신뢰가 무너진다.

그래서 배포를 설계할 때 나는 항상 역순으로 본다.

1. 터졌을 때 5분 안에 되돌릴 수 있는가?
2. 되돌린 뒤 원인 추적이 가능한가?
3. 그 상태에서 다시 배포할 수 있는가?

---

CI/CD를 쓰든 로컬 배포를 쓰든 기준은 같다.

- 검증 자동화가 재현 가능해야 하고
- 버전 추적성이 명확해야 하며
- 실패 시 복구 경로가 자동화돼야 한다.

SemVer를 붙이는 이유도 릴리즈 멋내기가 아니다.
문제 버전을 즉시 특정하기 위해서다.

---

키오스크/웹뷰 환경에서 리로드 전략은 더 까다롭다.

- 캐시 버스팅으로 파일 정합성 확보
- 네이티브 브릿지로 업데이트 신호 전달
- 유저 인터럽트 최소 시점에서 리로드

모바일 웹처럼 사용자가 앱을 닫고 다시 열기를 기대하면 실패한다.
상시 켜진 디바이스는 “멈추지 않는 업데이트”가 필요하다.

---

롤백도 브랜치만으론 늦다.

실전에서는 보통 세 가지를 같이 둔다.

- last-known-good 아티팩트 즉시 전환
- feature flag kill switch
- 점진 배포 중 임계치 초과 시 자동 중단

배포의 완성은 성공 배포 횟수가 아니라,
실패 배포의 피해 반경으로 판단하는 게 맞다.

## 배포 전략을 결정할 때 실제로 쓴 매트릭스

이 글의 핵심은 "CI/CD냐 로컬 배포냐"가 아니다. 어떤 방식을 택하든 실패를 빠르게 탐지하고 복구할 수 있어야 한다는 점이다. 그래서 우리 팀은 도구 선택보다 통제 지점을 먼저 확정했다.

첫 번째 축은 버전 추적성이다. 릴리즈는 SemVer를 기준으로 분류하고([SemVer](https://semver.org/)), 배포 아티팩트에는 커밋 해시와 빌드 시간을 강제 삽입했다. 장애 대응 시 "이게 어느 버전인지"를 추측하지 않게 만드는 것이 복구 시간을 가장 크게 줄였다.

두 번째 축은 호환성 정책이다. 브라우저 지원 범위가 모호하면 폴리필 비용과 오류 책임이 팀마다 달라진다. 그래서 browserslist를 조직 기준으로 고정해 빌드 타깃을 명시했다([Browserslist](https://github.com/browserslist/browserslist)).

세 번째 축은 출시 안전성이다. SRE의 출시 원칙처럼 단계적 반영과 즉시 중단 기준을 먼저 정의하고([Reliable Product Launches](https://sre.google/sre-book/reliable-product-launches/)), 실제 반영은 카나리 전략으로 운용했다([Argo Rollouts Canary](https://argo-rollouts.readthedocs.io/en/stable/features/canary/)).

키오스크/웹뷰는 업데이트 특성이 달라서 별도 규칙을 두었다. 웹뷰 API 차이를 기준으로 기능 가용 범위를 분리하고([Android WebView](https://developer.android.com/reference/android/webkit/WebView), [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)), 캐시 정책은 HTTP 캐시와 서비스워커 정책을 분리해 설계했다([HTTP Cache](https://web.dev/articles/http-cache), [SW + HTTP caching](https://web.dev/articles/service-worker-caching-and-http-caching)).

결론적으로 인프라/배포의 본질은 자동화 수준이 아니라, 실패를 통제 가능한 범위로 제한하는 운영 설계였다.

## 참고자료
- [SemVer](https://semver.org/)
- [Browserslist](https://github.com/browserslist/browserslist)
- [Google SRE - Reliable Product Launches](https://sre.google/sre-book/reliable-product-launches/)
- [Argo Rollouts - Canary](https://argo-rollouts.readthedocs.io/en/stable/features/canary/)
- [Android WebView Reference](https://developer.android.com/reference/android/webkit/WebView)
- [Apple WKWebView Documentation](https://developer.apple.com/documentation/webkit/wkwebview)
- [web.dev - HTTP Cache](https://web.dev/articles/http-cache)
- [web.dev - Service worker caching and HTTP caching](https://web.dev/articles/service-worker-caching-and-http-caching)

## 제가 배포 설계에서 가장 크게 바꾼 관점

예전에는 배포를 기술 이벤트로 봤다. 파이프라인이 잘 돌면 성공이라고 생각했다. 그런데 운영 이슈를 겪고 나서는 배포를 "서비스 신뢰 이벤트"로 보게 됐다. 같은 배포 성공이라도 사용자 체감이 나쁘면 실패에 가깝다는 걸 현장에서 여러 번 확인했다.

그래서 최근에는 배포 전 질문을 바꿨다.

- 이 변경이 사용자 흐름에 어떤 위험을 주는가?
- 실패했을 때 몇 분 안에 원복 가능한가?
- 원복 이후 재배포 판단을 어떤 지표로 할 것인가?

이 질문을 미리 합의하면, 사고 순간에도 팀이 덜 흔들린다. 반대로 질문이 없으면 도구가 좋아도 대응 품질이 들쑥날쑥해진다.

또한 저는 "자동화 = 완전 무인"이라는 생각도 경계하고 있다. 자동화는 반복 실수를 줄여주지만, 비정상 상황에서의 판단까지 대체해주진 않는다. 그래서 운영 시나리오마다 사람 판단이 필요한 지점을 명시하고, 그 판단 기준을 문서로 남기고 있다.

## 배포 품질을 위해 유지하는 최소 원칙

- 배포 전 체크리스트는 10개 이하로 단순화
- 롤백 절차는 신규 인원도 10분 내 수행 가능해야 함
- 장애 공지는 기술 용어보다 사용자 영향 중심으로 작성
- 배포 후 관측 지표는 팀 전체가 같은 대시보드에서 확인
- 회고는 "누가"보다 "어떤 장치가 없었는지" 중심으로 정리

이 원칙들은 아직도 계속 수정 중이다. 다만 분명한 건, 배포 품질은 특정 엔지니어의 숙련도보다 팀이 같은 절차를 얼마나 일관되게 따르느냐에 더 크게 좌우된다는 점이다.
