---
layout: post
title: "난해한 버그를 만났을 때 내가 쓰는 추적 순서 (메모리/하드웨어/성능)"
date: 2026-02-16 22:40:00 +0900
categories: [400-area]
tags: [debugging, performance, memory, kiosk, sourcemap]
description: "메모리 누수, 하드웨어 특화 장애, 소스맵 분기, 저사양 성능 이슈를 추적할 때 실제로 쓰는 순서를 기록했다."
---

버그를 빨리 잡는 개발자는 도구를 많이 아는 사람이 아니라,
순서를 잘 지키는 사람이라고 생각한다.

내가 현업에서 쓰는 순서는 아래와 같다.

---

**1단계: 현상 고정**

- 언제
- 어떤 동작 뒤에
- 얼마나 자주

이 세 가지를 고정하지 않으면, 이후 분석은 거의 운이다.

**2단계: 관측 포인트 추가**

로그를 늘리는 게 아니라, 경계 로그를 심는다.

- 라우트 전환 전/후
- 네트워크 요청 전/후
- 메모리 증가 시점

**3단계: 환경 분리**

코드 문제인지, 디바이스/OS 문제인지 먼저 가른다.
키오스크는 여기서 많이 갈린다.

**4단계: 최소 재현 시나리오**

복잡한 실서비스를 그대로 재현하려 하지 않고,
문제를 일으키는 가장 작은 시퀀스를 먼저 찾는다.

---

소스맵 전략도 같은 맥락이다.

운영에서 무조건 공개할 필요는 없다.
대신 릴리즈와 매핑 가능한 형태로 안전 업로드하면,
보안과 추적성을 같이 가져갈 수 있다.

저사양 최적화도 트릭보다 원칙이 먼저다.

- 레이아웃 재계산 줄이기
- 긴 메인 스레드 작업 분할
- transform/opacity 위주 애니메이션
- 필요할 때만 GPU 레이어 승격

문제 해결은 결국 화려한 해법보다,
문제를 좁히는 정확한 순서에서 나온다.

## 문제 해결 프로토콜을 표준화한 뒤 달라진 점

예전에는 장애가 나면 개인 경험에 의존해 접근했다. 어떤 날은 빨리 잡히고 어떤 날은 오래 걸렸다. 편차를 줄이기 위해 디버깅 프로토콜을 문서화했고, Chrome DevTools 공식 가이드를 기준으로 팀 공통 절차를 만들었다([DevTools Performance](https://developer.chrome.com/docs/devtools/performance), [Memory Problems](https://developer.chrome.com/docs/devtools/memory-problems)).

프로토콜 핵심은 아래 네 단계다.

1. 증상 시점 고정
2. 관측 지표 수집
3. 환경 분리 실험
4. 최소 재현 경로 확정

메모리 누수나 프레임 드랍처럼 복합 이슈에서는 성능 탭과 메모리 탭을 같이 보지 않으면 원인을 놓치기 쉽다. 렌더링 병목인지, 객체 누적인지, 이벤트 루프 정체인지 먼저 나눠야 했다.

일부 케이스는 Electron/Chromium 구조 이해가 있어야 설명이 가능했다. 그래서 Electron 성능 문서와 Chromium 멀티프로세스 아키텍처를 참고해, 브라우저 계층과 앱 계층의 병목을 분리해서 분석했다([Electron Performance](https://www.electronjs.org/docs/latest/tutorial/performance), [Chromium Multi-process Architecture](https://www.chromium.org/developers/design-documents/multi-process-architecture/)).

결과적으로 가장 큰 변화는 "문제 해결 속도"보다 "문제 해결 예측 가능성"이었다. 누가 대응하든 비슷한 품질로 원인을 좁힐 수 있게 되면서, 장애 대응이 개인기에서 팀 역량으로 이동했다.

## 참고자료
- [Chrome DevTools - Performance](https://developer.chrome.com/docs/devtools/performance)
- [Chrome DevTools - Memory Problems](https://developer.chrome.com/docs/devtools/memory-problems)
- [Electron - Performance](https://www.electronjs.org/docs/latest/tutorial/performance)
- [Chromium Multi-process Architecture](https://www.chromium.org/developers/design-documents/multi-process-architecture/)
- [Google SRE - Service Best Practices](https://sre.google/sre-book/service-best-practices/)
- [Google SRE - Postmortem Culture](https://sre.google/sre-book/postmortem-culture/)

## 제가 디버깅에서 특히 조심하려는 오판 패턴

문제 해결을 오래 하다 보면 익숙한 패턴에 빨리 끼워 맞추고 싶어질 때가 있다. 저도 그 유혹을 자주 느꼈고, 실제로 몇 번은 그 때문에 원인 파악이 늦어졌다. 그래서 최근에는 스스로를 견제하기 위한 기준을 따로 적어두고 있다.

첫 번째 오판은 "증상이 보이는 레이어가 원인 레이어일 것"이라는 착각이다. 화면 멈춤이 보이면 렌더링 코드부터 의심하기 쉽지만, 실제로는 네트워크 재시도 폭증이나 타이머 누수가 근본 원인인 경우도 많았다. 그래서 지금은 레이어를 역순으로 좁힌다. 네트워크/상태/렌더링/디바이스를 순서대로 분리해 가설을 세우면 불필요한 코드 수정을 줄일 수 있었다.

두 번째 오판은 "재현이 안 되면 운이 나쁜 것"이라는 생각이다. 예전에는 간헐 장애를 이렇게 받아들였는데, 나중에 돌아보면 관측점이 부족했던 경우가 대부분이었다. 그래서 현재는 재현 실패가 반복될수록 로그 포인트를 늘리는 대신, 상태 전이 경계(요청 시작, 응답 수신, 화면 반영, 사용자 입력)에서만 관측을 촘촘히 한다. 무작정 로그를 많이 남기면 오히려 노이즈가 커져 핵심 신호를 놓치기 쉽기 때문이다.

세 번째 오판은 "한 번 고쳤으니 끝났다"는 안도감이다. 성능/메모리 이슈는 환경 조건이 바뀌면 다시 나타날 수 있다. 그래서 수정 후에는 항상 회귀 관점 테스트를 붙인다. 특히 저사양 기기/긴 세션/불안정 네트워크 같은 극단 케이스를 재실행해, 같은 계열의 문제가 다시 생기지 않는지 확인한다.

저는 디버깅을 개인 역량 과시의 영역으로 보지 않으려 한다. 문제를 빨리 푸는 것도 중요하지만, 팀이 같은 문제를 반복하지 않게 만드는 것이 더 중요하다고 느끼기 때문이다. 그래서 요즘은 해결 기록을 "무엇을 고쳤는가"보다 "어떤 오판을 줄였는가" 중심으로 남기고 있다.

## 성능/안정성 이슈 회고 템플릿(개인 메모)

1. **증상**
- 사용자가 겪은 현상을 한 문장으로
- 발생 조건(시간, 기기, 동작)

2. **가설**
- 가능성 높은 원인 3개 이하
- 각 가설의 반증 조건

3. **검증**
- 어떤 관측 포인트로 확인했는지
- 어떤 실험으로 가설을 기각했는지

4. **수정**
- 임시 완화책과 근본 수정 분리
- 변경 범위와 리스크 명시

5. **재발 방지**
- 테스트 추가 여부
- 모니터링 항목 추가 여부
- 운영 문서 반영 여부

이 템플릿이 완벽하진 않지만, 문제를 정리하는 속도와 품질을 안정화하는 데는 확실히 도움이 됐다.
