---
layout: post
title: "기타 기술 질문 모음인데, 사실은 다 기본기 질문이다"
date: 2026-02-16 23:40:00 +0900
categories: [400-area]
tags: [cors, env, middleware, typescript, mobile-web, basics]
description: "Bounce, CORS, env, JS->TS, Next.js Middleware 같은 기타 질문을 실무 기준으로 빠르게 정리했다."
---

아래 질문들은 면접에서 ‘기타’로 분류되지만,
실제로는 기본기가 드러나는 질문들이다.

---

**모바일 바운스 효과**

바운스는 애니메이션 장식이 아니라 경계 피드백이다.
저항-복원 곡선을 과하게 주면 피곤하고,
약하게 주면 경계 인지가 안 된다.

**CORS**

프론트 이슈처럼 보이지만 본질은 서버 정책 문제다.
Same-Origin Policy 위에서,
서버가 허용 범위를 어떻게 선언하느냐의 문제다.

**env 관리**

빌드타임 변수와 런타임 변수를 분리하지 않으면
운영 사고가 반드시 난다.
민감정보는 클라이언트 번들에 들어가는 순간 끝이다.

**JS -> TS 전환**

모든 파일을 동시에 바꾸려 하지 않는다.
런타임 장애가 잦은 API 경계부터 잠그는 게 현실적이다.

**Next.js Middleware**

리다이렉트/리라이트/헤더 조작/가벼운 인증까지는 적합하다.
무거운 비즈니스 로직을 넣으면 병목이 된다.
미들웨어는 제어 레이어지, 도메인 처리 레이어가 아니다.

---

요약하면,
기타 질문은 잡학이 아니라
"원리를 경계에 적용할 수 있나"를 확인하는 질문이다.

## 기타 질문을 답할 때 기준점을 명확히 잡는 방법

기타 질문은 주제가 넓어서 대답이 산으로 가기 쉽다. 그래서 나는 항상 "정의 - 원리 - 실무 결정" 순서로 짧게 고정해서 답한다.

CORS는 브라우저 보안 정책에서 출발한다. 그래서 프론트에서 우회 기법을 말하기 전에, 서버가 어떤 `Access-Control-*` 정책을 가져야 하는지부터 설명한다([MDN CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)). 모바일 바운스 효과는 터치 이벤트 흐름과 경계 피드백 설계 문제로 정리하고([MDN Touch Events](https://developer.mozilla.org/en-US/docs/Web/API/Touch_events)), 과한 반동이 사용성에 어떤 부담을 주는지까지 말한다.

환경 변수 질문은 보안으로 연결한다. 12-Factor의 config 분리 원칙을 기준으로([12-Factor Config](https://12factor.net/config)), 민감정보는 클라이언트 번들에 두지 않는다는 점을 명확히 하고, 운영에서는 OWASP 비밀관리 가이드처럼 관리 정책을 분리해야 한다고 덧붙인다([OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)).

JS->TS 마이그레이션은 문법보다 우선순위 설계가 핵심이다. TypeScript 공식 문서 기준으로 strict 옵션의 단계적 적용을 설명하고([TS strict](https://www.typescriptlang.org/tsconfig/strict.html), [strictNullChecks](https://www.typescriptlang.org/tsconfig/strictNullChecks.html)), 프로젝트 참조로 빌드 경계를 나누는 방식까지 말하면 설득력이 높아진다([Project References](https://www.typescriptlang.org/docs/handbook/project-references)).

Next.js Middleware 질문은 범위 정의가 중요하다. 라우팅 제어/헤더 처리/가벼운 인증 분기는 적합하지만, 무거운 비즈니스 로직은 애플리케이션 계층으로 보내야 한다는 기준을 명확히 제시한다([Next.js Middleware](https://nextjs.org/docs/app/building-your-application/routing/middleware)).

## 참고자료
- [MDN - CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [MDN - Touch Events](https://developer.mozilla.org/en-US/docs/Web/API/Touch_events)
- [12-Factor App - Config](https://12factor.net/config)
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [TypeScript - strict](https://www.typescriptlang.org/tsconfig/strict.html)
- [TypeScript - strictNullChecks](https://www.typescriptlang.org/tsconfig/strictNullChecks.html)
- [TypeScript - Project References](https://www.typescriptlang.org/docs/handbook/project-references)
- [Next.js - Middleware](https://nextjs.org/docs/app/building-your-application/routing/middleware)

## 면접 질문을 정리하며 제가 계속 고치는 답변 습관

기타 기술 질문을 정리하다 보니, 과거 제 답변의 단점이 명확히 보였다. 아는 내용을 많이 말하려고 할수록 핵심이 흐려졌다. 그래서 요즘은 답변을 짧게 구조화하고, 확신이 없는 부분은 모른다고 말한 뒤 검증 경로를 제시하려고 한다.

예를 들어 CORS 질문에서 프록시나 헤더만 나열하면 깊이가 없어 보일 수 있다. 그래서 저는 원인(브라우저 보안 모델)과 해결 위치(서버 정책)부터 명확히 하고, 예외 케이스(credential 요청, preflight 실패)를 짧게 덧붙인다. 같은 방식으로 env 관리 질문에서도 단순히 `.env` 파일 이야기가 아니라 노출 경계와 비밀관리 정책을 중심으로 답하려고 한다.

또한 "정답처럼 말하는 태도"를 경계하고 있다. 기술 선택은 맥락 의존적이라, 단정적인 어조가 오히려 신뢰를 떨어뜨릴 때가 있다. 그래서 최근에는 "제가 경험한 환경에서는"이라는 전제를 먼저 두고, 반례 가능성도 같이 언급한다. 이 방식이 겸손해 보이기 위해서가 아니라, 실제로 더 정확한 설명에 가깝다고 느낀다.

## 제가 유지하려는 답변 원칙 5가지

1. 정의보다 문제 맥락을 먼저 설명한다.
2. 원리와 실무 결정을 분리해 말한다.
3. 단정이 필요한 경우 근거 링크를 함께 제시한다.
4. 반례 가능성을 짧게 언급한다.
5. 모르는 범위는 솔직히 말하고 확인 계획을 제시한다.

저는 이 원칙이 완성형이라고 생각하지 않는다. 다만 꾸준히 지키면 기술 지식보다 사고 방식이 전달된다는 점에서, 앞으로도 계속 다듬어볼 가치가 있다고 보고 있다.
