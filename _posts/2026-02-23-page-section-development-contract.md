---
layout: post
title: "‘이 정도면 됐죠?’를 없애기 위한 페이지/섹션 계약서"
date: 2026-02-16 15:00:00 +0900
categories: [300-project]
tags: [frontend, qa, design, collaboration, contract]
description: "개발-디자인-QA 사이의 완료 기준 차이를 줄이기 위해 도입한 페이지/섹션 계약 방식과 효과를 정리했다."
---

팀 커뮤니케이션에서 가장 비싼 문장은 보통 이거다.

“이 정도면 됐죠?”

누군가에게는 완료고, 누군가에게는 시작인 상태.
이 문장 하나가 하루를 날린다.

그래서 우리는 ‘감’ 대신 계약서를 만들었다.

---

계약서라고 해서 거창한 문서는 아니다.

각 섹션마다 4가지만 명시했다.

- 입력: 어떤 데이터가 오면
- 상태: 어떤 화면을 보여주고
- 행동: 어떤 상호작용을 허용하고
- 검증: 어떤 기준이면 완료인지

이걸 스토리/프리뷰와 같이 묶었다.

디자이너는 상태 누락을 먼저 잡고,
QA는 시나리오 누락을 먼저 잡고,
개발자는 구현 누락을 먼저 잡는다.

같은 자료를 보니까,
회의가 의견 싸움이 아니라 누락 점검이 됐다.

---

이 방식의 장점은 딱 두 가지였다.

1. 재작업 감소
2. 병렬 작업 증가

특히 병렬 작업이 컸다.

API가 완성되기 전에도 mock 상태로 QA가 돌 수 있었고,
디자인 수정도 구현 끝난 뒤가 아니라 중간에 바로 반영됐다.

결국 속도는 개발자 손이 빨라서 생긴 게 아니라,
완료 기준이 빨리 합의돼서 생겼다.

## 계약 기반 개발을 문서에서 테스트로 연결한 방식

페이지/섹션 계약이 실무에서 실패하는 가장 흔한 이유는 문서가 코드와 분리되기 때문이다. 그래서 이 프로젝트에서는 "계약 문서 작성"을 목표로 두지 않고, 계약이 테스트와 리뷰 규칙으로 연결되게 만들었다.

먼저 계약 항목을 최소 단위로 쪼갰다.

- 입력 계약: 값의 타입/범위/기본값
- 상태 계약: loading/empty/error/success
- 행동 계약: 클릭/재시도/취소 정책
- 관측 계약: 로그 이벤트/모니터링 키

이 구조는 Consumer-Driven Contract 접근에서 아이디어를 가져왔다([Consumer Driven Contracts](https://martinfowler.com/articles/consumerDrivenContracts.html)). API만 계약하는 게 아니라 UI 상태도 계약 대상으로 본 것이다. 팀별 검증 도구는 Pact 문서와 Storybook 테스트 가이드를 참고해 맞췄다([Pact](https://docs.pact.io/), [Storybook Tests](https://storybook.js.org/docs/writing-tests)).

또한 E2E만으로 품질을 보장하려는 습관을 줄였다. 구글 테스트 블로그의 글처럼, 모든 걸 E2E로 막으려 하면 피드백이 늦고 유지비가 급증한다([Just Say No to More End-to-End Tests](https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html)). 그래서 UI 계약은 컴포넌트/통합 테스트에서 먼저 검증하고, E2E는 핵심 경로만 유지했다.

디자인 쪽은 토큰 기반으로 계약했다. 스타일 값 자체를 고정하지 않고 토큰 키를 계약해 브랜딩 변경에도 파손을 줄였다([Design Tokens](https://www.designtokens.org/), [Format Module](https://tr.designtokens.org/format/)). 이 구조를 적용한 뒤에는 "완료 기준이 사람마다 다른 상태"가 눈에 띄게 줄었다.

## 참고자료
- [Martin Fowler - Consumer-Driven Contracts](https://martinfowler.com/articles/consumerDrivenContracts.html)
- [Pact Documentation](https://docs.pact.io/)
- [Storybook - Writing Tests](https://storybook.js.org/docs/writing-tests)
- [Storybook - Build Documentation](https://storybook.js.org/docs/writing-docs/build-documentation)
- [Google Testing Blog - End-to-End Tests](https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html)
- [Design Tokens Community Group](https://www.designtokens.org/)
- [Design Tokens Format Module](https://tr.designtokens.org/format/)

## 계약 기반 개발에서 제가 계속 점검하는 한계

계약 기반 개발이 만능은 아니다. 저는 이 방식이 효과적이라고 느끼지만, 몇 가지 부작용도 분명히 경험했다. 그래서 지금은 장점만 강조하기보다 한계를 함께 관리하려고 한다.

첫 번째 한계는 문서 과잉이다. 계약을 꼼꼼히 남기려다 보면 문서 작성이 구현보다 앞서 나가고, 팀이 문서를 부담으로 느끼기 시작한다. 이 상태가 되면 계약 문화는 오래 가지 못한다. 그래서 현재는 "실제로 깨진 적이 있거나, 깨지면 비용이 큰 항목"만 계약 문서에 남기고 나머지는 코드/테스트에 맡긴다.

두 번째 한계는 계약과 현실의 시차다. 기능은 빠르게 바뀌는데 계약 문서 갱신이 늦으면 오히려 잘못된 기준이 된다. 이를 줄이기 위해 계약 문서 업데이트를 PR 완료 조건에 넣었다. 번거롭지만 효과가 컸다. 특히 QA가 오래된 기준으로 테스트하는 일이 줄어들었다.

세 번째 한계는 사람별 해석 차이다. 같은 문장을 읽어도 개발자, 디자이너, QA가 다르게 이해할 수 있다. 그래서 글 설명만으로 끝내지 않고, 가능하면 예시 화면과 실패 시나리오를 같이 붙인다. 문장보다 사례가 훨씬 빠르게 합의를 만든다.

저는 아직도 "어디까지를 계약으로 고정할지"에서 많이 배우는 중이다. 너무 적으면 혼선이 생기고, 너무 많으면 속도가 느려진다. 결국 팀의 숙련도와 서비스 위험도에 맞춘 균형이 필요하다고 생각한다.

## 제가 실제로 쓰는 계약 문서 최소 템플릿

- 목적: 이 컴포넌트/섹션이 해결하는 사용자 문제
- 입력: 필수/선택, 기본값, 유효성 규칙
- 상태: 정상/로딩/빈 상태/오류/권한없음
- 행동: 클릭/입력/재시도/취소
- 예외: 타임아웃, API 실패, 중복 요청
- 검증: QA 시나리오 3~5개
- 관측: 로그 이벤트 이름과 필수 필드

이 템플릿은 가볍지만, 팀에서 반복적으로 실수하던 지점을 줄여주는 데 도움이 됐다. 저는 앞으로도 계약 문서를 "형식"이 아니라 "팀의 합의 메모"로 유지하려고 한다.
