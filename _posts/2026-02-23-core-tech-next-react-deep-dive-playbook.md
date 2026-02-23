---
layout: post
title: "Next.js/React 심화 질문, 내가 실제로 답하는 방식"
date: 2026-02-16 21:30:00 +0900
categories: [400-area]
tags: [nextjs, react, suspense, rsc, stale-closure, interview]
description: "next/image, Suspense, RSC 경계, preload/prefetch, staleTime/gcTime, stale closure를 실무 기준으로 답변한 노트."
---

면접에서 기술 질문을 받을 때 나는 정의부터 말하지 않는다.
먼저 “언제 문제가 됐는지”를 말한다.

## next/image

이미지 최적화의 핵심은 원본 압축이 아니라 전송 맥락이다.

- 디바이스 픽셀 비율
- 뷰포트 크기
- 캐시 가능성

여기에 맞춰 리사이즈/포맷을 분기한다.

placeholder blur도 감성 기능이 아니다.
레이아웃 공간을 먼저 확보해서 CLS를 막는 안전장치다.

## Suspense vs useEffect fetch

`useEffect` fetch는 렌더 후 요청이 시작돼 폭포수(Waterfall)가 생기기 쉽다.
Suspense는 로딩 경계를 컴포넌트 외부에서 제어할 수 있어서 화면 체감이 더 좋다.

핵심은 API 호출 함수가 아니라, 로딩 책임을 어디에 두느냐다.

## RSC / Client 경계

내 기준은 간단하다.

- 인터랙션 없고 데이터 조합 중심: 서버
- 이벤트/상태/브라우저 API 필요: 클라이언트

경계를 명확히 하면 번들 사이즈와 코드 책임이 동시에 정리된다.

## staleTime / gcTime

- staleTime: 다시 가져올지 판단하는 신선도
- gcTime: 안 쓰는 캐시를 버리기까지의 메모리 보관 시간

둘을 섞어 쓰면 “왜 refetch됐지?” “왜 메모리 남지?”가 동시에 생긴다.

## stale closure

이슈가 뜨면 우선 의존성 배열보다 "캡처 시점"을 본다.

- 렌더 시점 값
- 실행 시점 값

두 값을 분리해 로그 찍으면 대부분 답이 나온다.

## 질문을 실무 답변으로 확장할 때 붙이는 근거

면접에서 깊이를 보여주려면 개념 정의 다음에 "왜 그 선택이 합리적인지"를 근거로 말해야 한다. 그래서 핵심 질문마다 공식 문서 기준점을 같이 준비해 둔다.

`next/image`는 이미지 자체를 줄이는 도구가 아니라 전달 전략을 최적화하는 도구다. Next.js 문서에서 설명하듯 크기/포맷/로딩 전략이 함께 묶여 동작하므로([Next.js Images](https://nextjs.org/docs/app/getting-started/images), [Image Component](https://nextjs.org/docs/pages/api-reference/components/image)), CLS를 막으려면 placeholder만 넣는 게 아니라 레이아웃 선점 조건까지 같이 설계해야 한다.

Suspense는 로딩 UI를 예쁘게 만드는 기능이 아니라 렌더링 경계를 제어하는 기능이다([React Suspense](https://react.dev/reference/react/Suspense)). 데이터 페칭과 결합할 때는 fallback 위치, 경계 분할, 네트워크 병렬화를 같이 보지 않으면 오히려 사용자 경험이 흔들릴 수 있다. RSC와 클라이언트 컴포넌트 경계도 동일하다. 서버에서 계산할 수 있는 건 서버로 당기고, 사용자 상호작용만 클라이언트에 남기는 것이 기본 원칙이다([Server Components](https://react.dev/reference/rsc/server-components)).

라우팅 가속에서는 무조건 prefetch보다 조건부 preload가 효과적이었다. React Router의 pre-rendering/Link 동작을 기준으로([React Router pre-rendering](https://reactrouter.com/how-to/pre-rendering), [Link API](https://reactrouter.com/api/components/Link)) 사용자 이동 가능성이 높은 경로만 선로딩했다.

상태 캐시는 TanStack Query의 `staleTime`과 `gcTime`을 구분해 설명하면 설계 의도가 선명해진다. stale은 신선도 정책, gc는 메모리 보관 정책이다([Important Defaults](https://tanstack.com/query/latest/docs/framework/react/guides/important-defaults), [useQuery](https://tanstack.com/query/latest/docs/framework/react/reference/useQuery)). 이 두 개를 혼동하면 "왜 다시 가져왔지"와 "왜 메모리에 남지"가 동시에 생긴다.

## 참고자료
- [Next.js - Getting Started: Images](https://nextjs.org/docs/app/getting-started/images)
- [Next.js - Image Component](https://nextjs.org/docs/pages/api-reference/components/image)
- [React - Suspense](https://react.dev/reference/react/Suspense)
- [React - Server Components](https://react.dev/reference/rsc/server-components)
- [React Router - Pre-rendering](https://reactrouter.com/how-to/pre-rendering)
- [React Router - Link](https://reactrouter.com/api/components/Link)
- [TanStack Query - Important Defaults](https://tanstack.com/query/latest/docs/framework/react/guides/important-defaults)
- [TanStack Query - useQuery](https://tanstack.com/query/latest/docs/framework/react/reference/useQuery)

## 답변 깊이를 높이기 위해 제가 추가한 연습 방법

기술 면접에서 깊이는 지식량보다 사고 과정에서 드러난다. 그래서 저는 최근에 "질문을 받으면 바로 답하지 않고, 먼저 전제를 명확히 하는 연습"을 하고 있다. 예를 들어 Suspense 질문에서도 "클라이언트 단독인가, 서버 컴포넌트와 결합인가"를 먼저 확인하면 답변의 정확도가 올라간다.

또한 각 기술에 대해 "언제 쓰지 말아야 하는가"를 같이 정리해 두고 있다. `next/image`도 모든 상황에서 정답은 아니고, 매우 단순한 정적 리소스에서는 비용 대비 이점이 작을 수 있다. Suspense도 경계를 잘못 나누면 오히려 로딩 경험이 흔들린다. 이런 반례를 함께 설명하면 답변이 더 현실적이 된다.

저는 과거에 공식 문서 내용을 그대로 외워 말하는 실수를 자주 했다. 지금은 같은 주제를 "문제 상황 -> 선택 이유 -> 실패 가능성 -> 대응 전략" 순서로 재구성한다. 이렇게 정리하면 면접뿐 아니라 실제 설계 회의에서도 설명이 훨씬 명확해졌다.

## 제가 스스로 점검하는 모범 답변 체크리스트

- 질문의 맥락(서비스 규모/환경)을 먼저 확인했는가?
- 개념 정의를 2~3문장으로 짧게 끝냈는가?
- 실무 의사결정 기준을 명확히 말했는가?
- 반례/한계를 최소 1개 이상 언급했는가?
- 운영에서 측정할 지표를 함께 제시했는가?

이 체크리스트도 계속 보완 중이다. 저는 아직도 모든 질문에 완벽히 답한다고 생각하지 않는다. 다만 답변을 준비하는 과정에서 제 설계 습관을 되돌아볼 수 있다는 점에서, 이 연습 자체가 현업에도 분명히 도움이 된다고 느끼고 있다.
