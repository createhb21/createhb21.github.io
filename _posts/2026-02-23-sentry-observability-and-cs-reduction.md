---
layout: post
title: "Sentry 도입에서 진짜로 바꾼 것: 에러 로그가 아니라 팀의 대응 속도"
date: 2026-02-16 10:00:00 +0900
categories: [300-project]
tags: [sentry, observability, frontend, incident, cs]
description: "회원 앱에 Sentry를 도입하면서 장애를 CS 이후가 아니라 CS 이전에 발견하도록 대응 체계를 바꾼 기록."
---

Sentry를 붙이기 전에도 우리는 장애를 ‘알고’ 있었다. 문제는 항상 너무 늦게 알았다는 점이다.

장애 흐름은 늘 같았다.

1. 사용자 문의
2. CS 전달
3. 개발자 추적
4. 재현 실패
5. 임시 패치

이 구조는 기술 문제가 아니라 시간 문제였다.

---

Sentry 도입을 하면서, 도구 세팅보다 먼저 룰을 정했다.

- 알림은 많이 받는 게 아니라, 중요한 것만 받는다.
- 에러 건수보다 영향 범위를 본다.
- 릴리즈 정보와 소스맵은 반드시 한 세트로 묶는다.

도입 초반에는 알림이 너무 많아서 오히려 피로했다.

그래서 fingerprint를 다시 설계하고,
에러를 도메인 담당 기준으로 라우팅했다.

“같은 원인”은 한 이슈로 모으고,
“사용자 영향”이 큰 건 즉시 채널로 올렸다.

---

가장 효과가 컸던 포인트는 breadcrumb였다.

장애 직전 사용자 행동이 남으니까,
어떤 버튼 이후 어떤 API에서 어떤 상태로 터졌는지 흐름이 잡혔다.

그 순간부터 장애 대응이
“감”에서 “증거”로 바뀌었다.

---

수치보다 체감이 먼저 바뀌었다.

- 재현 시간이 눈에 띄게 줄었고
- 핫픽스 정확도가 올라갔고
- CS가 먼저 알려주는 장애 비율이 떨어졌다.

메모에 적어둔 "CS 발생 감소"는 결과였고,
원인은 결국 이거였다.

> 에러를 기록한 게 아니라, 대응 시스템을 다시 설계했다.

## 관측 체계를 지표 중심으로 재정의한 과정

Sentry 도입 초반에 가장 흔한 실패는 "이슈를 많이 모으는 것"이었다. 실제로는 이슈 수가 아니라 우선순위 분류와 복구 속도가 중요했다. 그래서 이 체계를 다시 설계할 때 Sentry 공식 문서의 릴리즈/알림/이슈 모델을 기준으로 삼았다([Sentry Releases](https://docs.sentry.io/product/releases/), [Alerts](https://docs.sentry.io/product/alerts/), [Issues](https://docs.sentry.io/product/issues/)).

특히 소스맵/릴리즈 매핑은 강제 규칙으로 만들었다. 같은 에러라도 어떤 릴리즈에서 생겼는지 추적이 안 되면 회고가 불가능해진다. 그래서 JS 소스맵 업로드와 릴리즈 태깅을 배포 파이프라인 필수 단계로 고정했다([React sourcemaps](https://docs.sentry.io/platforms/javascript/guides/react/sourcemaps/)).

운영 지표는 SRE의 error budget 개념을 참고해 정의했다. "에러 절대 건수" 대신 서비스 허용 실패율을 기준으로 경보 임계치를 잡으니, 알림 피로가 줄고 대응 우선순위가 명확해졌다([SRE Workbook - Error Budget Policy](https://sre.google/workbook/error-budget-policy/)).

브라우저/런타임 지원 범위도 CS와 직접 연결되므로, 지원 매트릭스를 문서화해 "재현 가능한 이슈"로 빠르게 정리했다([Sentry supported browsers](https://docs.sentry.io/platforms/javascript/guides/react/troubleshooting/supported-browsers)). 이 작업 이후 CS 감소가 나타난 이유는 도구가 아니라 운영 규칙이 바뀌었기 때문이다.

## 참고자료
- [Sentry - React Sourcemaps](https://docs.sentry.io/platforms/javascript/guides/react/sourcemaps/)
- [Sentry - Releases](https://docs.sentry.io/product/releases/)
- [Sentry - Alerts](https://docs.sentry.io/product/alerts/)
- [Sentry - Issues](https://docs.sentry.io/product/issues/)
- [Sentry - Supported Browsers](https://docs.sentry.io/platforms/javascript/guides/react/troubleshooting/supported-browsers)
- [Google SRE Workbook - Error Budget Policy](https://sre.google/workbook/error-budget-policy/)
- [Google SRE - Service Best Practices](https://sre.google/sre-book/service-best-practices/)

## 관측 지표를 운영 언어로 번역하면서 배운 점

Sentry를 잘 쓰기 시작한 시점은, 개발팀 지표와 운영팀 지표를 같은 표에 놓기 시작한 때였다. 이전에는 에러 건수나 이슈 개수만 보고 대응 우선순위를 정했는데, 운영팀 입장에서는 "사용자 영향"이 더 중요했다. 이 간극을 줄이기 위해 지표를 다시 번역했다.

예를 들어 동일한 에러라도 발생 위치가 온보딩/결제/예약인지에 따라 우선순위를 다르게 잡았다. 또한 에러 절대 건수보다 영향 세션 비율과 재시도 실패율을 같이 보니, 대응 순서가 훨씬 명확해졌다. 제가 초기에 놓친 건 기술 지표가 곧 비즈니스 지표라고 착각한 부분이었다.

또 하나 배운 점은 알림 민감도의 균형이다. 알림을 너무 많이 받으면 무뎌지고, 너무 적게 받으면 놓친다. 그래서 임계치를 고정값으로 두지 않고, 이벤트 성격과 시간대에 따라 분리했다. 이벤트 오픈 시간처럼 트래픽이 몰리는 구간은 기준을 더 엄격히, 평시에는 신호 품질을 우선하는 쪽으로 운영했다.

운영 커뮤니케이션도 개선할 여지가 많았다. 장애를 기술 용어로만 공유하면 CS와 운영팀은 판단이 어렵다. 그래서 최근에는 이슈 템플릿을 바꿔 "사용자 영향", "임시 조치", "예상 복구 시점"을 먼저 적는다. 기술 원인은 뒤에 적어도 충분히 논의할 수 있었다.

## 앞으로 더 고도화하려는 관측 항목

- 도메인별 에러 예산 분리 관리
- 릴리즈 후 24시간 집중 관측 자동화
- 동일 이슈 재발 주기 추적
- 사용자 재시도 성공률 대시보드화
- 운영팀용 요약 리포트 자동 생성

저는 이 시스템이 아직 완성됐다고 생각하지 않는다. 다만 분명히 느끼는 건, 장애를 "개발자만의 문제"로 보지 않을 때 대응 품질이 좋아진다는 점이다. 앞으로도 관측 체계를 팀 전체의 공통 언어로 만드는 데 더 집중하려고 한다.
