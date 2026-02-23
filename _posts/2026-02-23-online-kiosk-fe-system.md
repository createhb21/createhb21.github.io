---
layout: post
title: "온라인 키오스크 FE 시스템, 결국은 ‘운영 런북’까지 포함해야 완성된다"
date: 2026-02-16 19:00:00 +0900
categories: [300-project]
tags: [kiosk, deployment, testing, runbook, frontend]
description: "온라인 키오스크 FE 시스템을 구축하며 개발/배포/테스트를 하나의 운영 사이클로 연결한 방법을 정리했다."
---

키오스크 프로젝트에서 내가 마지막으로 고친 건 화면이 아니었다. 런북이었다.

왜냐하면 현장에서 터지는 문제는 대부분 코드보다 운영 경계에서 났기 때문이다.

---

내가 팀에 공유한 최소 운영 루프는 아래였다.

**배포 전**

- 빌드 버전/커밋 해시 확인
- 스모크 시나리오 자동 실행
- 롤백 대상 아티팩트 고정

**배포 중**

- 점진 반영
- 주요 이벤트 로그 모니터링
- 임계치 초과 시 자동 중단

**배포 후**

- 헬스체크 확인
- 현장 주요 플로우 수동 검증
- 이슈 발생 시 즉시 이전 아티팩트 전환

---

핵심은 도구가 아니었다.

"개발 끝 -> 배포 시작"이라는 분리를 버리고,
개발 안에 배포/복구 설계를 포함한 게 전환점이었다.

이후부터는 릴리즈가 이벤트가 아니라 루틴이 됐다.

## 운영 런북을 버전 2로 올리면서 바뀐 점

처음에는 "배포 체크리스트"가 있었고, 나중에는 "복구 가능한 배포 시스템"이 됐다. 이 둘은 비슷해 보여도 결과가 다르다. 체크리스트는 사람이 빼먹으면 끝나지만, 시스템은 실패를 전제로 움직인다.

배포 전략은 SRE 문서에서 말하는 출시 신뢰도 원칙을 기준으로 다시 묶었다. 특히 [Reliable Product Launches](https://sre.google/sre-book/reliable-product-launches/)에서 강조하는 단계적 노출과 즉시 중단 조건을 키오스크 환경에 맞춰 적용했다. 모든 매장을 동시에 바꾸지 않고, 장비군을 나눠 카나리 반영 후 확대하는 방식으로 전환했다([Argo Rollouts Canary 개념](https://argo-rollouts.readthedocs.io/en/stable/features/canary/)).

문제는 키오스크가 모바일 앱처럼 재시작 타이밍을 기대하기 어렵다는 점이었다. 그래서 캐시 정책을 먼저 정리했다. 해시된 정적 자산은 장기 캐시, 엔트리 문서는 짧은 캐시로 분리하고([HTTP Cache](https://web.dev/articles/http-cache)), 서비스 워커를 쓰는 경로는 네트워크 우선/캐시 우선 정책을 케이스별로 분기했다([Service worker caching + HTTP caching](https://web.dev/articles/service-worker-caching-and-http-caching)). 업데이트 지연이 생겨도 안전한 버전 조합으로 수렴하도록 설계한 것이다.

릴리즈 추적은 SemVer만 붙이는 수준에서 멈추지 않았다. 앱 화면에서 즉시 확인 가능한 버전/커밋 정보를 노출하고([SemVer](https://semver.org/)), 장애 리포트에는 동일 식별자가 자동 포함되도록 맞췄다. "무슨 버전인지 모른다"는 상황을 없애는 게 롤백 시간 단축에 가장 크게 기여했다.

웹뷰 한계도 운영 변수였다. 동일 코드라도 [Android WebView](https://developer.android.com/reference/android/webkit/WebView)와 [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)의 동작 차이로 문제 양상이 달랐다. 그래서 런북에 플랫폼별 금지 API/주의 케이스를 명시해, 배포 전에 위험 영역을 선제적으로 차단했다. 배포는 한 번의 성공이 아니라, 실패했을 때 빠르게 복구되는 구조여야 한다는 걸 이 프로젝트에서 가장 선명하게 배웠다.

## 참고자료
- [Google SRE Book - Reliable Product Launches](https://sre.google/sre-book/reliable-product-launches/)
- [Argo Rollouts - Canary](https://argo-rollouts.readthedocs.io/en/stable/features/canary/)
- [web.dev - HTTP Cache](https://web.dev/articles/http-cache)
- [web.dev - Service worker caching and HTTP caching](https://web.dev/articles/service-worker-caching-and-http-caching)
- [SemVer Specification](https://semver.org/)
- [Android WebView Reference](https://developer.android.com/reference/android/webkit/WebView)
- [Apple WKWebView Documentation](https://developer.apple.com/documentation/webkit/wkwebview)
- [SRE Workbook - Error Budget Policy](https://sre.google/workbook/error-budget-policy/)

## 운영 단계에서 제가 특히 조심하는 현실적인 문제

키오스크는 개발 환경과 운영 환경의 간극이 크다. 사무실에서는 잘 동작하던 기능이 현장에서는 전혀 다르게 느껴질 때가 많다. 저는 이 차이를 줄이기 위해 "개발 완료" 기준을 운영 관점으로 다시 정의하려고 노력하고 있다.

첫째, 업데이트 타이밍 문제다. 키오스크는 사용 중단이 곧 비즈니스 손실로 이어지기 때문에, 강제 새로고침은 마지막 수단이어야 한다. 그래서 최근에는 사용자의 작업 맥락을 감지해 업데이트 타이밍을 늦추거나, 다음 유휴 구간에서 안전하게 반영하는 방식을 우선 검토한다.

둘째, 장애 공지 문제다. 기술적으로는 짧은 오류여도 현장에서는 즉시 불안으로 번진다. 그래서 장애 감지 시 내부 알림만 보내는 것이 아니라, 사용자에게 보여줄 최소 안내 문구를 같이 준비한다. 개인적으로는 이 부분이 "개발 범위 밖"으로 여겨지기 쉬운데, 실제 경험상 서비스 신뢰에 큰 영향을 줬다.

셋째, 복구 연습 문제다. 문서만으로는 위기 대응이 잘 되지 않는다. 그래서 월 단위로 짧은 롤백 리허설을 돌려, 담당자가 바뀌어도 같은 절차를 재현할 수 있는지 확인한다. 이 리허설은 비용이 들지만 실제 사고 시 복구 시간을 확실히 줄여준다.

## 다음 분기 개선 항목

- 운영 상태 대시보드에 매장/디바이스 그룹 뷰 추가
- 업데이트 반영률과 실패율을 시간대별로 추적
- 장애 안내 문구 템플릿을 상황별로 표준화
- 현장 담당자용 1페이지 복구 가이드 배포
- 배포 후 24시간 집중 모니터링 자동화

제가 아직 확신하지 못하는 부분도 있다. 모든 매장에 동일 정책을 적용하는 것이 항상 최선인지에 대해서는 더 실험이 필요하다. 다만 지금까지의 경험으로는, 운영 다양성을 인정하고 규칙을 유연하게 가져갈수록 안정성이 좋아졌다는 쪽에 무게를 두고 있다.
