---
layout: post
title: "(번역) Cypress vs Playwright: 500개의 E2E 테스트를 돌려봤다"
date: 2026-01-18 00:30:00 +0900
categories: [600-archive]
tags: [testing, e2e, cypress, playwright, frontend, QA, CI, translation]
---

### 서론

E2E 테스트.

프론트엔드 개발자라면 누구나 한 번쯤 고민해봤을 주제다. "Cypress 쓸까, Playwright 쓸까?" 혹은 "지금 쓰는 도구를 바꿔야 하나?"

특히 **CI에서 테스트가 랜덤하게 깨지는** 경험을 반복하다 보면, '이게 정말 맞는 도구인가?' 하는 의문이 들기 마련이다.

오늘 소개할 글은 실제로 **500개의 E2E 테스트**를 Cypress에서 Playwright로 옮긴 개발자의 생생한 경험담이다. 단순 비교가 아니라, 실제로 뭐가 깨지고, 뭐가 좋아졌는지 솔직하게 풀어낸다.

---

> _원문: [Cypress vs Playwright: I Ran 500 E2E Tests in Both. Here's What Broke](https://medium.com/@coding_with_tech/cypress-vs-playwright-i-ran-500-e2e-tests-in-both-heres-what-broke-2afc448470ee) by Coding With Tech_

---

## 솔직하게 말할게

두 달 전, 우리 팀 QA 리드가 그만뒀다. 그냥 나가버렸다. 슬랙에 "flaky 테스트들 잘 해결하세요 ㅎ" 메시지만 남기고 사라졌다.

> `flaky`는 실행 환경이나 타이밍 문제로 결과가 오락가락하는, 신뢰할 수 없는 테스트(Flaky Test)를 의미한다.

우리한테는 Cypress로 작성된 500개의 E2E 테스트가 있었다. 절반은 랜덤하게 실패했고, 나머지 절반은 돌리는 데만 45분이 걸렸다. 즉, CI 파이프라인은 재앙에 가까웠다.

그래서 테스트 인프라가 불타는 상황에서 합리적인 사람이라면 누구나 할 법한 일을 했다... **Playwright로 전부 다시 짜보기로.**

**스포일러: 더 나아진 점도 있었지만 만능 해결책은 아니었다. 자세한 내용은 아래에서 설명하겠다.**

<br/>

## 배경: 어쩌다 이 지경이 됐나

우리 앱은 꽤 평범한 SaaS 제품이다. 사용자 대시보드, 데이터 테이블, 폼, 파일 업로드... 뭐 특별할 거 없는 구성이다.

우리 Cypress 테스트 현황:

- 총 500개 테스트
- CI 실행 시간: 42~48분
- Flaky 테스트 비율: **약 30%**
- 아무도 믿지 않는 테스트: **전부**

모든 PR이 테스트를 돌렸다. 그리고 매번 5~8개가 랜덤하게 실패했다. 실패할 때마다 파이프라인 전체를 다시 돌려야 했다.

개발자들은 테스트를 안 믿게 됐다. 실패 뜨면 어깨 한번 으쓱하고, 뭔지 보지도 않고 "재실행" 버튼 누르곤 했다.

**이것은 E2E 테스트가 사실상 사망 선고를 받았다는 결정적인 증거였다.**

<br/>

## 1주차: Playwright 마이그레이션 (신혼여행 기간) - 모든 게 쉬워 보이던 시기

하나의 플로우를 골랐다. 사용자 등록. 충분히 간단하다.

**Cypress 버전:**

```javascript
describe("User Registration", () => {
  it("should register a new user", () => {
    cy.visit("/signup");
    cy.get('[data-testid="email"]').type("test@example.com");
    cy.get('[data-testid="password"]').type("password123");
    cy.get('[data-testid="submit"]').click();
    cy.url().should("include", "/dashboard");
  });
});
```

**Playwright 버전:**

```javascript
test("should register a new user", async ({ page }) => {
  await page.goto("/signup");
  await page.fill('[data-testid="email"]', "test@example.com");
  await page.fill('[data-testid="password"]', "password123");
  await page.click('[data-testid="submit"]');
  await expect(page).toHaveURL(/.*dashboard/);
});
```

꽤 비슷해 보이지 않는가? 나도 그렇게 생각했다.

마이그레이션 자체는 기계적인 작업처럼 느껴졌다. `cy.`를 `page.`로 바꾸고, 문법 좀 맞추면 끝.

이틀 만에 50개를 옮겼다. 전부 통과했다.

똑똑해진 기분이 들었다. **그리고 그건, 꽤 위험한 신호였다.**

<br/>

## 2주차: Flakiness의 실체

여기서부터 재밌어진다.

아까 그 flaky한 Cypress 테스트들, 기억나는가? 30% 확률로 랜덤하게 실패하던 그 녀석들.

Playwright에서는 **100% 일관되게 실패했다.**

잠깐, 그게 더 나쁜 거 아니냐고? 그런데 사실은, 더 나은 거였다. 이유를 설명해보자.

**Cypress는 문제를 숨겼다.** 빌트인 재시도 로직, 자동 대기, 타이밍 이슈를 가리는 타임아웃... 테스트가 실패해도 Cypress는 다시 시도했고, 결국 “통과”시켜버렸다. 문제가 있었는지조차 모른 채로.

**Playwright는 문제를 드러냈다.** 자동 재시도는 없다. 마법 같은 대기도 없다. 테스트에 레이스 컨디션이 있으면? 실패한다. 매번. 시끄럽게.

처음엔 이렇게 생각했다. “이 테스트들, Cypress에서는 됐는데?”
하지만 곧 깨달았다.

사실 Cypress는 그냥 **조용히 실패하고 있었을 뿐이다.**

<br/>

## 우리가 몰랐던 레이스 컨디션

테스트 중 하나는 폼 제출 후 성공 메시지를 확인하는 시나리오였다.

<br/>

**Cypress에서:**

```javascript
cy.get('[data-testid="submit"]').click();
cy.contains("Success!").should("be.visible");
```

Cypress에서는 70%는 통과했고, 30%는 실패했다. 우리는 그냥 “flaky하네” 하고 넘어갔다.

<br />
<br />

**Playwright에서:**

```javascript
await page.click('[data-testid="submit"]');
await expect(page.locator("text=Success!")).toBeVisible();
```

**100% 실패했다.**

이유는 간단했다. 성공 메시지는 API 호출이 끝난 뒤에 나타난다. API가 빠르면 통과했고, 느리면 실패했다.

Cypress의 자동 대기와 재시도 로직이 이 문제를 덮어버렸던 거다. Playwright는 그러지 않았다.

**수정:**

```javascript
await page.click('[data-testid="submit"]');
await page.waitForResponse((resp) => resp.url().includes("/api/submit"));
await expect(page.locator("text=Success!")).toBeVisible();
```

이제 100% 통과한다. **진짜 올바른 것을 테스트하고 있으니까.**

이 패턴이 수십 개 테스트에서 반복됐다. 결과적으로 **Playwright는 더 나은 테스트를 작성하도록 강제했다.**

<br/>

## 속도 비교 (숫자는 거짓말을 안 한다)

500개 테스트를 전부 변환한 뒤, 두 테스트 러너를 나란히 실행해봤다.

**Cypress (원본):**

| 항목             | 값          |
| ---------------- | ----------- |
| 총 실행 시간     | 42분        |
| 병렬화           | 4 workers   |
| 평균 테스트 시간 | 5.2초       |
| Flaky 테스트     | 147개 (30%) |

<br/>
<br/>

**Playwright (마이그레이션 후):**

| 항목             | 값        |
| ---------------- | --------- |
| 총 실행 시간     | 18분      |
| 병렬화           | 8 workers |
| 평균 테스트 시간 | 2.1초     |
| Flaky 테스트     | 0개       |

**Playwright는 2.3배 빨랐다.** 그것도 별도의 최적화 없이.

이유는 명확했다.

1. **더 나은 병렬화.** Playwright는 worker를 훨씬 효율적으로 활용한다. Cypress는 구조적인 오버헤드가 있다.
2. **더 빠른 브라우저 자동화.** Playwright의 프로토콜은 Cypress의 CDP 기반 구현보다 빠르다.
3. **재시도 로직 오버헤드 없음.** Cypress는 모든 명령을 자동으로 재시도한다. 그만큼 시간이 든다.

하지만 진짜 승리는 따로 있었다. **Flaky 테스트가 0개가 됐다.**

CI 파이프라인이 다시 신뢰를 회복했다. 개발자들은 무지성 재실행 대신, 실패한 테스트를 실제로 읽기 시작했다.

<br/>

## 마이그레이션 중 깨진 것들

다 좋았던 건 아니다. Playwright로 옮기면서 확실히 아쉬웠던 지점들도 있었다.

### 1. 디버깅 경험

Cypress는 E2E 도구 중 **디버깅 경험만큼은 최고**다. 진짜다.

타임 트래블 디버거, 자동 스크린샷, 무엇이 어떤 순서로 일어났는지 정확히 보여주는 커맨드 로그까지. 솔직히 말하면 아름답다.

Playwright 디버깅은... 괜찮다. 실패하면 스크린샷이 남고, `page.pause()`로 단계별 실행도 가능하다. 하지만 같은 느낌은 아니다.

Cypress에서는 테스트가 실패하면 “아, 여기서 이렇게 됐구나”가 바로 보인다. Playwright에서는 실패 로그를 읽고, 스크린샷을 보면서 상황을 추론해야 한다.

테스트가 복잡해질수록 이 차이는 더 크게 느껴졌다. 그럴 때마다, 솔직히 말해 Cypress가 꽤 그리웠다.

### 2. 네트워크 모킹

Cypress의 `cy.intercept()`는 강력하고 직관적이다.

```javascript
cy.intercept("POST", "/api/users", { statusCode: 201 });
```

Playwright의 `page.route()`는... 좀 덜 직관적이다.

```javascript
await page.route("**/api/users", (route) => route.fulfill({ status: 201 }));
```

같은 개념인데 Cypress API가 더 깔끔하다. 작은 거지만 수백 개 테스트 작성하면 티가 난다.

### 3. 컴포넌트 테스팅 미흡

Cypress에는 컴포넌트 테스팅이 있다. React 컴포넌트를 마운트해서 격리된 상태로 테스트하면 끝이다.

Playwright에는 없다. 정확히 말하면, 실험적인 형태로는 존재하지만 아직 프로덕션 레디라고 보긴 어렵다.

그래서 **컴포넌트 테스팅이 목적이라면, 여전히 Cypress가 낫다.**

<br/>

## Playwright가 더 잘하는 것 (속도 외에)

### 1. 진짜 되는 멀티 브라우저 테스팅

Cypress는 Chrome, Firefox, Edge를 지원한다. 이론상으로는.

하지만 실제로는 다른 브라우저들이 flaky 지옥에 빠지기 쉽고, 결국 대부분 Chrome만 쓰게 된다.

Playwright는 Chromium, Firefox, WebKit을 지원한다. **그리고 이건 말 그대로 다 된다. 안정적으로.**

우리는 전체 테스트 스위트를 세 브라우저에서 모두 돌린다. 그 과정에서 Cypress로는 놓쳤던 브라우저별 버그들을 실제로 잡아냈다.

### 2. Codegen

Playwright에는 codegen이 있다 — 브라우저 상호작용을 녹화해서 테스트 코드를 생성해주는 도구다.

```bash
npx playwright codegen https://your-app.com
```

완벽하진 않다. 생성된 코드는 정리가 필요하다. 하지만 빠른 프로토타이핑에는? 놀랍다.

**Cypress에는 이런 거 없다.**

### 3. API 테스팅

Playwright는 브라우저 없이 API를 직접 테스트할 수 있다.

```javascript
test("API endpoint works", async ({ request }) => {
  const response = await request.post("/api/users", {
    data: { name: "Test User" },
  });
  expect(response.status()).toBe(201);
});
```

API 테스트와 E2E 테스트를 같은 스위트에서 섞어 돌릴 수 있고, 컨텍스트도 공유된다. 생각보다 훨씬 유용하다.

Cypress는 플러그인이나 각종 우회 없이는 사실상 불가능하다.

### 4. Trace Viewer

Playwright 테스트가 CI에서 실패하면 trace 파일을 받아서 로컬에서 재생할 수 있다.

```bash
npx playwright show-trace trace.zip
```

테스트 실행 전체가 보인다. 네트워크 요청, 콘솔 로그, 매 단계 스크린샷, DOM 스냅샷까지 전부.

Cypress 라이브 디버거만큼 화려하진 않지만, **CI 실패 상황에서는 오히려 이쪽이 더 낫다.**

<br/>

## 아무도 안 말하는 진짜 비용

500개 테스트 마이그레이션에 3주가 걸렸다. 풀타임이었다. 나 혼자.

그 3주 동안 기능은 하나도 안 만들었고, 버그도 안 고쳤고, 생산적인 일은 전혀 못 했다.

가치가 있었을까?

우리에게는 있었다. Cypress 테스트가 너무 망가져서, 아무도 더 이상 믿지 않았으니까.

**하지만 당신의 Cypress 테스트가 잘 돌아간다면? 빠르고 안정적이라면? 마이그레이션하지 마라.**

마이그레이션 비용은 진짜다. 학습 곡선도 진짜다. 도구 격차도 진짜다.

**이미 충분히 고통받고 있을 때만 마이그레이션해라.**

<br/>

## 예상 못 한 Playwright 장점들

### 진짜 똑똑한 Auto-Waiting

둘 다 요소(Element)를 기다린다. 하지만 Playwright의 구현은 한 수 위다.

Cypress는 요소가 **존재하기를** 기다린다. Playwright는 요소가 **actionable 하기를** 기다린다.

actionable이란 이런 상태다.

- 보이는 상태
- 안정된 상태 (애니메이션 중 아님)
- 활성화된 상태
- 다른 요소에 안 가려진 상태

이 차이가, 우리가 미처 몰랐던 버그들을 잡아냈다. 기술적으로는 보이지만 로딩 스피너에 가려져 있던 버튼 같은 것들 말이다.

### Expect 라이브러리

Playwright의 expect는 Cypress assertion보다 확실히 강력하다.

```javascript
// 요소가 특정 텍스트 가질 때까지 대기
await expect(page.locator(".message")).toHaveText("Success!");

// 요소 개수 대기
await expect(page.locator(".item")).toHaveCount(5);

// assertion별 커스텀 타임아웃
await expect(page.locator(".slow")).toBeVisible({ timeout: 30000 });
```

더 깔끔하고, 더 읽기 쉽고, 더 유연하다.

### 빌트인 접근성 테스팅

Playwright는 axe-core와 기본적으로 통합되어 접근성 테스팅을 지원한다.

```javascript
import { injectAxe, checkA11y } from "axe-playwright";

test("page is accessible", async ({ page }) => {
  await page.goto("/dashboard");
  await injectAxe(page);
  await checkA11y(page);
});
```

접근성 이슈를 자동으로 잡아낸다. Cypress도 플러그인은 있지만, Playwright 쪽 통합이 훨씬 매끄럽다.

<br/>

## 내가 처음부터 시작한다면 어떻게 할까?

처음부터 다시 시작한다면 이렇게 고르겠다.

**Cypress 써라:**

- 작은 팀 (5명 미만)
- 디버깅 경험이 중요함
- 컴포넌트 테스팅을 적극적으로 함
- 테스트가 이미 잘 돌아감

**Playwright를 써라:**

- 속도와 병렬화가 중요함
- 여러 브라우저를 반드시 테스트해야 함
- flakiness 문제가 이미 있음
- API 테스트와 E2E 테스트를 함께 운영함

**마이그레이션하지 마라:**

- 현재 설정이 잘 돌아감
- 2~4주 마이그레이션 시간을 낼 수 없음
- 팀이 새 도구 학습을 원하지 않음

**최고의 테스팅 도구는, 팀이 실제로 쓰는 도구다.**

<br/>

## 불편한 진실

이 모든 작업 이후 테스트는 더 빨라졌고, 더 안정적이 되었으며, 버그도 더 잘 잡는다.

하지만 여전히 문제가 있다. E2E 테스트는 유닛 테스트보다 느리고, 유지보수가 어렵고, UI가 바뀌면 쉽게 깨진다.

**진짜 교훈은 이것이다. E2E 테스트를 더 적게 써라.**

우리가 500개 테스트를 가지게 된 이유는, 무언가 깨질 때마다 테스트를 계속 추가했기 때문이다. 오래된 테스트는 지우지 않았고, 정말 필요한지 고민도 하지 않았다.

마이그레이션 이후 **200개를 지웠다.** 중복된 것들, 오래된 플로우, 유닛 테스트가 더 잘 커버하는 것들이다.

지금은 300개다. 12분에 돈다. 크리티컬 패스만 커버한다.

**Playwright가 과잉 테스팅 문제를 해결한 건 아니다. 단지 테스트를 더 빨리 돌게 만들었을 뿐이다.**

<br/>

## 백엔드 엔지니어들을 위해

E2E 테스팅은 퍼즐의 일부일 뿐이다. 브라우저 자동화와 싸우지 않을 때는, 보통 Spring Boot 서비스가 왜 RAM을 잡아먹는지, 로컬에서는 잘 되던 DB 쿼리가 왜 프로덕션에서 죽는지 디버깅하고 있다.

백엔드 테스트와 운영 문제를 겪고 있면, 내가 계속 발견한 패턴을 바탕으로 참고 자료를 작성했다.

백엔드 실패 플레이북은 실제 시스템에서 실제로 어떤 문제가 발생하는지, 그리고 운영 환경에서 발생하기 전에 이를 발견하는 방법을 다룬다. 이론은 없고, 실제 운영 환경에서 발생하는 문제들을 정리했다.

[여기](https://devrimozcay.gumroad.com/l/menhx)에서 확인할 수 있다.

<br/>

## 최종 결론

**Playwright가 이겼다.** 우리 상황에서는.

더 빠른 테스트, 더 높은 안정성, 더 나은 크로스 브라우저 지원.

하지만 Cypress가 나쁜 도구라는 뜻은 아니다. 많은 팀에게 여전히 더 나은 선택일 수 있다.

맞는 도구는 팀, 애플리케이션, 그리고 가장 아픈 지점에 따라 달라진다.

우리에게는 마이그레이션이 고통의 값을 했다. 당신에게는 아닐 수도 있다.

이제 실례하겠다. Firefox에서만 실패하고 Chrome에서는 통과하는 로그인 테스트를 디버깅하러 가야 한다.

**어떤 건 절대 안 바뀐다.**

---

**당신 차례:** Cypress를 쓰고 있는가, Playwright를 쓰고 있는가? 이런 문제를 겪어본 적 있는가? 댓글로 남겨달라.

마이그레이션을 고민 중이라면, 먼저 현재 테스트 케이스들을 분석해봐라. 마이그레이션이 필요 없을 수도 있다.

<br/>

## 원문 저자 소개

나는 수년간 실제 프로덕션 시스템을 구축하고 운영해온 엔지니어이자 창업가다. 시스템이 터질 때 무슨 일이 벌어지는지도 직접 겪어왔다.

새벽에 터지는 장애, 불분명한 근본 원인, 위험한 릴리즈, 팀에서 한두 명만 이해하는 시스템들까지 전부 경험했다.

지금은 그 고통스럽고 비싼 경험들을 도구와 실천 방법으로 바꾸는 일을 하고 있다.

팀들이 프로덕션 장애가 인시던트로 커지기 전에 감지하고, 이해하고, 예방할 수 있도록.

만약 당신 팀이 이런 문제로 고민하고 있다면:

- 서비스가 천천히 메모리를 먹다가 결국 크래시
- 아무도 이해하지 못하는데 계속 오르는 클라우드 비용
- “랜덤”처럼 느껴지지만 반복되는 장애
- 한두 명만 진짜 이해하고 있는 시스템

👉 [Devrim's Engineering Notes](https://substack.com/@devrimozcay1)
링크를 통해 나에게 연락할 수 있다.
