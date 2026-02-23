---
layout: post
title: "Next.js/React 심화 질문, 내가 실제로 답하는 방식"
date: 2026-02-23 21:30:00 +0900
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
