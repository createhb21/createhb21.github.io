---
layout: post
title: "화이트스크린 사건 보고서: ‘코드를 못 봐도’ 원인을 끝까지 찾았던 방법"
date: 2026-02-16 23:00:00 +0900
categories: [400-area]
tags: [electron, kiosk, star, incident, troubleshooting]
description: "외주 코드 접근 불가 상태에서 일렉트론 키오스크 화이트스크린 문제를 재현하고 해결한 STAR 기반 문제 해결 기록."
---

이건 내가 가장 자주 꺼내는 사례다.

외주 웹 서비스를 일렉트론으로 패키징해 납품하는 프로젝트에서,
특정 가맹점에서만 Blank DOM이 터졌다.

코드를 직접 수정하기 어려운 상황이었고,
대금 회수 지연까지 걸린 민감한 이슈였다.

---

처음 이슈를 받았을 때 가장 위험한 건
"감으로 원인 정하기"였다.

그래서 순서를 강제로 지켰다.

- 현장 모니터링 상시화(팀뷰어)
- 장애 직전 리소스 상태 기록
- 저사양 조건을 로컬에서 강제 재현

몇 번의 재현 끝에 패턴이 보였다.

메모리 압박이 심해질 때 렌더링이 붕괴했다.
즉, 소프트웨어 로직 단일 원인보다
하드웨어 리소스 한계가 트리거였다.

---

해결은 두 축으로 나눴다.

1) 단기 안정화

- 일렉트론 런타임 옵션 조정
- 불필요 백그라운드 프로세스 정리

2) 재발 방지

- 최소 사양 기준 문서화
- 설치 환경 점검 체크리스트 배포
- 저사양 장비 교체 가이드 제시

---

이 사건 이후 내 디버깅 원칙은 하나로 정리됐다.

> 재현 불가능한 버그는 없다. 관측이 부족했을 뿐이다.

## 포렌식 관점에서 재현한 절차

화이트스크린 이슈에서 가장 큰 오해는 "코드를 못 보니 원인을 못 찾는다"였다. 실제로는 코드 접근성보다 관측 설계가 더 중요했다. 그래서 증상을 코드 라인 단위가 아니라 프로세스 상태 단위로 재구성했다.

일렉트론은 크롬 멀티프로세스 모델 위에서 동작하기 때문에, 렌더러 프로세스 압박이 생기면 화면 공백처럼 보이는 현상이 나타날 수 있다([Chromium Multi-process Architecture](https://www.chromium.org/developers/design-documents/multi-process-architecture/)). 이 가설을 검증하기 위해 로컬에서 메모리/CPU 압박 시나리오를 만들고, 렌더러 응답 지연과 화면 공백 발생 시점을 매칭했다.

도구는 [Chrome DevTools Performance](https://developer.chrome.com/docs/devtools/performance), [Memory Problems](https://developer.chrome.com/docs/devtools/memory-problems) 가이드를 기준으로 사용했다. GC 직후 메모리 회복 패턴, long task 발생 구간, 프레임 드랍 지점을 함께 보면 "느림"과 "멈춤"을 구분할 수 있다.

런타임 측면에서는 Electron 성능 가이드의 권장사항을 따라 프로세스 부담을 줄였다([Electron Performance](https://www.electronjs.org/docs/latest/tutorial/performance)). 렌더링 파이프라인에 영향을 주는 이벤트는 `web-contents` 레이어에서 수집해 상태를 기록했고([web-contents API](https://www.electronjs.org/docs/latest/api/web-contents)), 장비별 최소 사양 미달 시에는 기능 제한 모드로 진입하도록 운영 정책을 추가했다.

이 과정을 거치면서 "원인 미상"이라는 표현을 제거할 수 있었다. 현장 장애는 대부분 설명 가능했고, 설명 가능해지면 대응과 설득도 쉬워진다. 이 사건이 남긴 가장 큰 자산은 코드 수정이 아니라 재현 절차 자체였다.

## 참고자료
- [Electron - Performance](https://www.electronjs.org/docs/latest/tutorial/performance)
- [Electron - web-contents API](https://www.electronjs.org/docs/latest/api/web-contents)
- [Chromium Multi-process Architecture](https://www.chromium.org/developers/design-documents/multi-process-architecture/)
- [Chrome DevTools - Performance](https://developer.chrome.com/docs/devtools/performance)
- [Chrome DevTools - Memory Problems](https://developer.chrome.com/docs/devtools/memory-problems)
- [Google SRE - Postmortem Culture](https://sre.google/sre-book/postmortem-culture/)

## 사건 이후 제가 바꾼 디버깅 습관

화이트스크린 사건 이후 가장 크게 바뀐 건 "확신의 속도"를 늦춘 것이다. 예전에는 첫 가설이 맞을 거라 믿고 깊게 파는 편이었는데, 이 사건을 겪고 나서는 가설을 빠르게 세우되 더 빨리 버리는 연습을 하게 됐다. 디버깅에서 자존심은 종종 시간을 잃게 만든다는 걸 배웠다.

특히 현장 장애는 개발 환경의 직관이 잘 맞지 않는다. 그래서 이제는 "재현 로그"를 꼭 남긴다. 어떤 조건에서 어떤 순서로 무엇을 확인했고, 어떤 가설을 왜 폐기했는지를 기록해두면 다음 대응자가 같은 시행착오를 반복하지 않는다. 이 기록은 문서 한 장이지만, 팀 입장에서는 큰 자산이 된다.

또한 하드웨어 이슈가 연관된 사건은 운영팀과의 협업 없이는 해결이 어렵다는 점도 체감했다. 개발팀만의 관점으로 보면 코드 수정만 찾게 되지만, 실제 원인은 장비 상태나 OS 자원 점유율일 수 있다. 이후에는 운영팀과 공통 점검표를 만들고, 사고 시 동일한 관측 데이터를 공유하도록 프로세스를 바꿨다.

저는 아직도 간헐 장애를 만날 때마다 긴장한다. 다만 예전과 달라진 점은 "무엇부터 볼지"가 분명해졌다는 것이다. 관측 경계, 실험 조건, 복구 우선순위가 정리돼 있으면 어려운 문제도 조금씩 좁혀갈 수 있다.

## 재현 불가 이슈 대응용 개인 체크리스트

- 증상 설명을 사용자 관점 문장으로 먼저 고정
- 발생 환경(기기/OS/네트워크/시간대) 즉시 수집
- 가설 3개 이하로 제한하고 반증 실험 먼저 수행
- 임시 완화책과 근본 수정책을 분리해 기록
- 재발 방지 항목을 운영 문서와 테스트에 동시 반영

저는 이 체크리스트가 완벽하다고 생각하지 않는다. 다만 위기 상황에서 팀이 흔들리지 않게 붙잡아주는 최소 기준으로는 충분히 도움이 된다고 느끼고 있다.
