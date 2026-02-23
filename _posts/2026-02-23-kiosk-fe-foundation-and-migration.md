---
layout: post
title: "7스튜디오 키오스크 앱을 ‘납품물’이 아니라 ‘운영 시스템’으로 바꾼 과정"
date: 2026-02-16 09:00:00 +0900
categories: [300-project]
tags: [kiosk, frontend, architecture, migration, white-label]
description: "7스튜디오 키오스크 FE를 운영 가능한 시스템으로 바꾸며, 확장성과 유지보수성을 확보한 의사결정 기록."
---

처음 이 프로젝트를 받았을 때 목표는 단순했다. “빨리 오픈한다.”

그런데 한 달만 지나도 목표 문장이 바뀌었다.

> “빠르게 오픈하는 것”보다 “오픈 이후를 버티는 것”이 훨씬 어렵다.

---

첫 오픈은 생각보다 잘 끝났다. 문제는 그다음이었다.

- 매장별 요구가 조금씩 달랐고
- 키오스크 디바이스별 제약이 달랐고
- 브랜딩 커스터마이징이 반복적으로 추가됐다.

처음엔 분기 코드로 막았다. `if`가 늘수록 속도는 빨랐지만, 두 번째 릴리즈부터는 수리 비용이 더 컸다.

그래서 팀에서 다음 질문을 던졌다.

- 이걸 프로젝트 복제로 갈 건가?
- 아니면 공통 기반을 먼저 만들 건가?

나는 후자를 밀었다. 이유는 단순했다. 복제는 이번 스프린트를 살리고, 기반은 다음 10번의 스프린트를 살린다.

---

내가 잡은 기준은 세 줄이었다.

1. 공통 코어는 절대 매장 정책을 알지 않는다.
2. 매장/브랜드 차이는 런타임 설정으로만 표현한다.
3. 디바이스 연동은 어댑터 레이어에서만 처리한다.

이 세 줄이 정해지고 나서부터 구조가 정리됐다.

- 화면 컴포넌트는 도메인 의도만 남고
- 브랜드는 토큰과 설정으로 분리되고
- 디바이스 API는 교체 가능한 인터페이스로 좁혔다.

결과적으로 “카스코 개발로 이관” 같은 조직 변화가 와도 코드베이스는 흔들리지 않았다.

---

가장 큰 수확은 기능이 아니라 감각이었다.

이전에는 FE를 “UI 구현 계층”으로 봤다면,
이 작업 이후엔 FE를 “변경 비용을 설계하는 계층”으로 보게 됐다.

요약하면 이렇다.

- 납품 성공: 당연히 필요
- 운영 성공: 그보다 더 중요

그리고 운영 성공은 결국 아키텍처에서 시작했다.

## 전환 기준을 문서화해 둔 이유

당시 이관 과정에서 가장 위험했던 건 기술 난이도보다 "기준 부재"였다. 그래서 전환 기준표를 따로 만들었다.

- 어떤 조건이면 레거시 유지
- 어떤 조건이면 신규 코어 흡수
- 어떤 조건이면 어댑터 분리

이 기준은 Strangler 접근의 원칙을 참고해([Strangler Fig Application](https://martinfowler.com/bliki/StranglerFigApplication.html)) 기능 단위로 적용했고, 설정/환경 차이는 12-Factor config 분리 원칙으로 묶었다([12-Factor Config](https://12factor.net/config)).

또한 키오스크 운영 환경은 웹뷰 제약이 큰 만큼, 플랫폼별 허용 기능을 별도 체크리스트로 두었다([Android WebView](https://developer.android.com/reference/android/webkit/WebView), [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)). 이 문서가 없었으면 사람마다 판단이 달라져 운영 리스크가 다시 커졌을 것이다.

요약하면, 이관은 코드를 옮기는 작업이 아니라 기준을 옮기는 작업이었다.

## 참고자료
- [Martin Fowler - Strangler Fig Application](https://martinfowler.com/bliki/StranglerFigApplication.html)
- [12-Factor App - Config](https://12factor.net/config)
- [Android WebView Reference](https://developer.android.com/reference/android/webkit/WebView)
- [Apple WKWebView Documentation](https://developer.apple.com/documentation/webkit/wkwebview)
- [Google SRE - Service Best Practices](https://sre.google/sre-book/service-best-practices/)
- [Google SRE Workbook - Error Budget Policy](https://sre.google/workbook/error-budget-policy/)

## 전환 이후 제가 남긴 리스크 레지스터

실제 이관이 끝난 뒤에도 긴장을 늦추기 어려웠다. 시스템은 한 번 안정화돼도 다음 변경에서 다시 흔들릴 수 있기 때문이다. 그래서 저는 "완료 보고"보다 "리스크 레지스터"를 먼저 정리했다. 프로젝트 회고에서 가장 많이 반복된 질문은 늘 비슷했다.

- 어떤 변경이 다시 분기 지옥을 만들 수 있는가?
- 어떤 요청이 코어 침범 신호인가?
- 어떤 장애가 운영에서 가장 치명적인가?

이 질문에 답하기 위해 리스크를 세 등급으로 나눴다.

1. **즉시 차단 리스크**: 코어 계약 파손, 인증/결제 흐름 파손
2. **관측 강화 리스크**: 성능 저하, 특정 디바이스 이슈 증가
3. **문서 보강 리스크**: 신규 인원 온보딩 시 오해 가능 지점

특히 2번이 중요했다. 성능 저하는 즉시 장애로 드러나지 않아 방치되기 쉽다. 그래서 WebView 환경에서 발생 가능한 병목을 미리 표로 남기고, 릴리즈 때마다 체크하도록 운영했다. 저는 이 작업이 다소 번거롭더라도 장기적으로는 가장 비용이 적게 든다고 생각한다.

그리고 한 가지 더 반성한 지점이 있다. 초기에는 기술 결정을 제가 빠르게 내리는 데 집중했는데, 그 과정에서 맥락 공유가 충분하지 않을 때가 있었다. 이후에는 중요한 구조 변경 전에 "왜 이 선택을 했는지"를 짧게라도 기록해 팀이 같은 배경을 보게 만들었다. 이 작은 습관이 불필요한 재논쟁을 많이 줄였다.

아직도 완벽하다고 말할 수는 없다. 다만 분명한 건 있다. 운영 가능한 시스템은 한 번의 구현이 아니라, 반복 가능한 판단 기준으로 만들어진다는 점이다. 저는 그 기준을 더 단단하게 만드는 쪽으로 계속 개선해볼 생각이다.
