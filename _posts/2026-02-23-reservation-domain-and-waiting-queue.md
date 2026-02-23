---
layout: post
title: "골프 예약/자동 대기열에서 배운 것: ‘가능’이라고 보여주는 순간의 책임"
date: 2026-02-16 12:00:00 +0900
categories: [300-project]
tags: [reservation, queue, concurrency, ux, frontend]
description: "골프 예약과 자동 대기열 기능을 구현하며 동시성 충돌과 사용자 신뢰를 함께 다뤘던 실전 기록."
---

예약 화면에서 버튼 하나는 단순한 버튼이 아니다.

사용자에게는 그게 약속이다.

> “지금 예약 가능합니다.”

문제는 같은 시간대에 여러 명이 동시에 누르는 순간 시작된다.

---

초기 버전에서 마주친 증상은 이랬다.

- 두 사용자가 동시에 예약 성공처럼 보임
- 뒤늦게 한 명만 확정되고 다른 한 명은 실패
- 재시도 중 중복 요청이 섞이며 혼란 증가

기술적으로는 동시성 이슈였다.
사용자 입장에서는 “서비스를 못 믿겠다”는 감정이었다.

---

우리가 바꾼 건 UI 문구보다 상태 모델이었다.

예약 플로우를 아래처럼 쪼갰다.

`idle -> checking -> reserved | queued | failed | expired`

중요한 건 각 상태에서 가능한 행동을 제한하는 것이었다.

- `checking` 중엔 재요청 차단
- `queued`에선 이탈/재진입 규칙 명시
- `failed`에선 사유와 다음 행동을 같이 제공

요청에는 idempotency key를 넣어 중복 확정을 막았다.

---

이 작업 이후 내가 바꾼 문장이 있다.

예전엔 “예약 기능 구현했다”라고 적었고,
지금은 “예약 신뢰도를 설계했다”라고 적는다.

작은 차이처럼 보이지만,
실무에선 이 차이가 CS 비용과 브랜드 신뢰를 가른다.

## 동시성 충돌을 줄이기 위해 참고한 설계 원칙

예약/대기열 문제를 풀 때 가장 먼저 확인한 건 HTTP 수준의 멱등 개념이었다. 재시도 요청이 자연스럽게 발생하는 도메인에서는 "같은 요청을 여러 번 보내도 결과가 안정적이어야 한다"는 조건이 핵심이다([RFC 9110 Idempotent Methods](https://www.rfc-editor.org/rfc/rfc9110#section-9.2.2)).

실무에서는 서버 메서드 속성만으로 부족해 애플리케이션 레벨 idempotency key를 추가했다. 이 패턴은 결제 도메인에서 검증된 접근이어서 Stripe 문서를 참고해 요청 재시도 안전성을 확보했다([Stripe idempotent requests](https://docs.stripe.com/api/idempotent_requests), [Low-level errors and idempotency](https://docs.stripe.com/error-low-level#idempotency)).

사용자 경험 쪽에서는 실패 메시지를 구조적으로 바꿨다. 단순 오류 안내 대신 "현재 상태 + 다음 행동"을 같이 주는 방식이 재시도율에 더 효과적이었다. 이 부분은 에러 메시지 가이드의 원칙을 적용했다([NN/g Error Message Guidelines](https://nnngroup.com/articles/error-message-guidelines/)).

또한 예약 대기열은 정상 플로우보다 이탈/재진입 플로우에서 불만이 커지기 쉬워, 상태 전이표를 운영 문서로 함께 관리했다. 장애 후 회고에서는 postmortem 관점으로 "누가 실수했는지"보다 "어떤 상태 전이가 허술했는지"를 남겼고, 같은 유형의 충돌을 줄일 수 있었다([Postmortem Culture](https://sre.google/sre-book/postmortem-culture/)).

## 참고자료
- [RFC 9110 - Idempotent Methods](https://www.rfc-editor.org/rfc/rfc9110#section-9.2.2)
- [Stripe API - Idempotent requests](https://docs.stripe.com/api/idempotent_requests)
- [Stripe - Error handling and idempotency](https://docs.stripe.com/error-low-level#idempotency)
- [NN/g - Error-Message Guidelines](https://nnngroup.com/articles/error-message-guidelines/)
- [Google SRE - Postmortem Culture](https://sre.google/sre-book/postmortem-culture/)
- [Google SRE Workbook - Error Budget Policy](https://sre.google/workbook/error-budget-policy/)

## 실패를 줄이기 위해 제가 수정한 커뮤니케이션 방식

예약/대기열 도메인을 다룰 때 제가 처음 저지른 실수는 "기술적으로 맞게 구현하면 사용자가 납득하겠지"라고 생각한 것이었다. 실제 운영에서는 정반대였다. 기술적으로는 정합해도, 사용자에게 과정이 설명되지 않으면 불신이 쌓였다. 특히 대기열은 사용자의 심리적 긴장이 높은 도메인이라, 작은 모호함도 강한 불만으로 이어졌다.

그래서 이후에는 프론트 상태 설계와 함께 문구 설계를 같은 우선순위로 다뤘다. 예를 들어 기존에는 `예약 실패`처럼 포괄적으로 보여주던 메시지를, 현재 상태와 다음 행동을 분리해 안내했다. "대기열이 갱신 중입니다. 30초 후 자동 재시도합니다." 같은 문구는 기술적으로 단순하지만 사용자에게는 중요한 안전장치가 된다.

또한 저는 한동안 "낙관적 UI"를 지나치게 선호했다. 빠르게 반응하는 화면은 분명 장점이지만, 예약처럼 충돌 가능성이 큰 도메인에서는 확정 전 안내 문구가 반드시 필요했다. 그래서 현재는 낙관적 반영을 하더라도 `확정 전 상태`를 분명히 표시하고, 실패 시 되돌림 규칙을 명시한다. 이 작은 원칙 하나가 CS 문의를 크게 줄였다.

아직 개선할 점도 많다. 대기 시간 예측 정확도는 여전히 환경 변수에 민감하고, 사용자의 네트워크 상태에 따라 경험 편차도 생긴다. 저는 이 부분을 "알고리즘 문제"만으로 보지 않고, 사용자 안내 전략과 함께 풀어야 한다고 보고 있다.

## 다음 반복에서 적용하려는 예약/대기열 개선안

1. **상태 전이 가시성 강화**
- 사용자에게 현재 상태를 1문장으로 명확히 안내
- 대기열 갱신 주기와 예상 대기 범위를 함께 표시

2. **재시도 안전성 고도화**
- 동일 세션의 중복 요청을 더 엄격히 차단
- 재시도 이력 기반으로 비정상 패턴 감지

3. **실패 안내 표준화**
- 실패 유형별 메시지/행동 가이드를 고정
- 운영팀과 동일 용어를 쓰도록 정리

4. **관측 이벤트 세분화**
- 대기열 이탈 시점, 재진입 시점, 확정 실패 원인을 분리 수집
- 월별로 실패 유형 상위 3개를 리뷰

5. **운영 대응 룰 정비**
- 특정 임계치 초과 시 자동 공지 노출
- 수동 개입 기준을 운영 문서에 명시

제가 이 도메인을 통해 배운 가장 큰 교훈은, 신뢰는 기능이 아니라 경험의 일관성에서 만들어진다는 점이었다. 기술적으로 99% 맞아도, 사용자가 불안하면 서비스는 실패한다. 그래서 저는 지금도 "정합성"과 "안심감"을 함께 설계하려고 노력하고 있다.
