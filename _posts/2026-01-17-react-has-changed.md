---
layout: post
title: "(번역) React는 변했고, 당신의 Hook도 변해야 한다"
date: 2026-01-17 22:00:00 +0900
categories: [600-archive]
tags:
  [
    react,
    hooks,
    useEffect,
    useEffectEvent,
    useSyncExternalStore,
    useDeferredValue,
    translation,
    architecture,
  ]
description: "React 18/19 시대에 맞는 Hook 사용법. useEffect 남용을 줄이고 useSyncExternalStore, useDeferredValue 등 현대적 패턴을 활용하자."
---
### 서론

우리는 종종 `useEffect`를 React의 만능열쇠처럼 사용하곤 한다.

데이터 페칭, 이벤트 리스너 등록, 상태 동기화.
이걸 전부 `useEffect` 하나로 해결하려 들면 코드가 빠르게 복잡해진다.
그러다 보면 의도치 않은 렌더링 이슈나 **Race Condition**과 싸우게 된다.

**특히 키오스크 앱처럼 24시간 켜져 있어야 하는 장시간 동작 애플리케이션을 생각해보자.**
여기에 고객 기기가
**안드로이드 7 혹은 11 같은 저성능 구형 기기**라면 문제는 더 심각해진다.

이런 극한 환경에서 과도한 `useEffect` 사용은 단순 버그로 끝나지 않는다.
예상치 못한 사이드 이펙트가 비용으로 바로 이어진다.
메모리 누수나 불필요한 연산이 쌓이면 기기가 멈추거나 느려진다.
결국 **치명적인 사용자 경험 저하**와 **금전적 손실**로 연결된다.

React 18과 19를 거치며 플랫폼은 진화했다.
이제 Hook 사용 습관도 그 흐름에 맞춰 **업데이트할 때**가 아닐까?

---

> _원문: [React has changed, your Hooks should too](https://allthingssmitty.com/2025/12/01/react-has-changed-your-hooks-should-too/) by Matt Smith_

---

### React는 변했다

React Hook이 등장한 지도 몇 년이 지났다.
그런데 많은 코드베이스는 아직 과거 방식에 머물러 있다.
약간의 `useState`, 남용되는 `useEffect`, 깊이 고민 없이 반복되는 복사·붙여넣기 패턴.
우리 모두 한 번쯤은 그런 코드를 봤을 것이다.

하지만 Hook은 단순히 생명주기 메서드(Lifecycle Method)를 대체하는 도구가 아니다.
더 표현력 있고 모듈화된 아키텍처를 만들기 위한 **디자인 시스템**에 가깝다.

React 18/19를 거치며 동시성(Concurrent) 시대가 본격화됐다.
데이터 처리 방식, 특히 비동기 처리 방식이 크게 달라졌다.
이제 `Server Components`, `use()`, `Server Actions`, 프레임워크 레벨 데이터 로딩을 사용할 수 있다.
클라이언트 컴포넌트 안에서도 비동기를 다루는 접근이 더 다양해졌다.

그래서 현대적인 Hook 패턴이 어떤 모습인지,
React가 개발자를 어떤 방향으로 이끄는지,
우리가 자주 빠지는 함정은 무엇인지 차례대로 살펴보자.

<br/>

### `useEffect`의 함정

`useEffect`는 여전히 가장 오용되고 있는 훅이다.
데이터 페칭, 파생 값(derived values) 계산, 단순 상태 변환 로직까지.
원래 **그 자리에 있지 않아야 할 로직**이 `useEffect`라는 '쓰레기통'으로 들어가곤 한다.

컴포넌트가 **"유령이 들린 것처럼"** 이상하게 동작하기 시작하는 지점이 여기다.
예상 못 한 타이밍에 리렌더링되거나, 필요 이상으로 자주 실행된다.

```javascript
useEffect(() => {
  fetchData();
}, [query]);
// 쿼리가 바뀔 때마다 실행됨.
// 하지만 새 값이 실질적으로 같은 경우(effectively the same)에도 불필요하게 실행될 수 있음.
```

이런 고통의 주원인은
**파생된 상태(Derived State)**와 **사이드 이펙트(Side Effect)**를
구분하지 않고 섞어 쓰는 데 있다.

React는 이 둘을 서로 전혀 다른 방식으로 취급한다.

<br/>

### React가 의도한 대로 Effect 사용하기

사실 React가 제시하는 기본 규칙은 놀라울 만큼 단순하다.

1. _**진짜 사이드 이펙트(Side Effect)에만 `useEffect`를 사용하세요.**_
   _외부 세계와의 상호작용(네트워크 요청, DOM 조작, 구독 등)에만 한정하세요._
2. _**그 외에는 렌더링 중에 계산하세요.** (Derived State)_

```javascript
// Good: useEffect 대신 useMemo 사용
const filteredData = useMemo(() => {
  return data.filter((item) => item.includes(query));
}, [data, query]);
```

Effect가 꼭 필요한 경우라면 `useEffectEvent`가 도움이 된다.
의존성 배열(dependency array)을 어지럽히지 않고도,
Effect 내부에서 최신 props나 state에 접근할 수 있다.

```javascript
const handleSave = useEffectEvent(async () => {
  await saveToServer(formData);
});
```

`useEffect`를 작성하기 전에 스스로 물어보자.

- **이것이 외부 요인(네트워크, DOM, 구독)에 의해 주도되는가?**
- **아니면 렌더링 중에 계산할 수 있는가?**

후자라면 `useMemo`, `useCallback` 같은 도구나
프레임워크 기능을 쓰는 편이 컴포넌트를 더 견고하게(robust) 만든다.

> Note: `useEffectEvent`를 의존성 배열 규칙을 회피하는 치트키로 쓰지는 말자.
> 이건 Effect 내부 로직을 최적화하기 위해 설계된 도구다.

<br/>

### 커스텀 훅

커스텀 훅은 단순히 중복 코드를 줄이는 용도가 아니다.
핵심은 **도메인 로직을 컴포넌트에서 분리해서 UI가 UI 역할에만 집중하게 만드는 것**이다.

예를 들어, 윈도우 리사이즈 이벤트 처리 로직을 컴포넌트에 직접 작성하면 코드가 난잡해진다.

```javascript
// Bad: 컴포넌트 안에 섞여있는 로직
useEffect(() => {
  const listener = () => setWidth(window.innerWidth);
  window.addEventListener("resize", listener);
  return () => window.removeEventListener("resize", listener);
}, []);
```

이걸 커스텀 훅으로 옮기면:

```javascript
// Good: 캡슐화된 로직
function useWindowWidth() {
  const [width, setWidth] = useState(
    typeof window !== "undefined" ? window.innerWidth : 0,
  );

  useEffect(() => {
    const listener = () => setWidth(window.innerWidth);
    window.addEventListener("resize", listener);
    return () => window.removeEventListener("change", listener);
  }, []);

  return width;
}
```

훨씬 깔끔하고 테스트하기도 좋다.
컴포넌트는 구현 세부 사항(implementation details)을 알 필요도 없어진다.

<br/>

### `useSyncExternalStore`

React 18에 도입된 `useSyncExternalStore`는
구독(subscription), 티어링(tearing), 빈번한 업데이트에서 생기던 버그를 많이 줄여줬다.

`matchMedia`, 스크롤 위치, 혹은 서드파티 스토어(Store)가
렌더링 시점마다 서로 다른 값(inconsistent values)을 반환해 본 적이 있을 것이다.
이 API는 바로 그 문제를 해결하려고 만들어졌다.

**언제 쓰는가?**

- 브라우저 API (`matchMedia`, 페이지 가시성, 스크롤 위치)
- 외부 스토어 (Redux, Zustand, 커스텀 구독 시스템)
- 성능에 민감하거나 이벤트 중심적인 것들

```javascript
function useMediaQuery(query) {
  return useSyncExternalStore(
    (callback) => {
      const mql = window.matchMedia(query);
      mql.addEventListener("change", callback);
      return () => mql.removeEventListener("change", callback);
    },
    () => window.matchMedia(query).matches,
    () => false, // SSR fallback
  );
}
```

> ⚠️ 주의: `useSyncExternalStore`는 동기적(synchronous) 업데이트를 보장한다.
> `useState`를 1:1로 대체하기 위한 기능은 아니다.

<br/>

### Transitions & Deferred Values

사용자가 타이핑하거나 필터링할 때 앱이 버벅거린다면,
React의 동시성 도구(Concurrency Tools)가 도움이 된다.
마법은 아니지만, **'긴급한 업데이트'**와 **'비싼 업데이트'**의 우선순위를 조절해준다.

```javascript
const [searchTerm, setSearchTerm] = useState("");
const deferredSearchTerm = useDeferredValue(searchTerm);

const filtered = useMemo(() => {
  // 무거운 필터링 작업은 지연된 값을 사용
  return data.filter((item) => item.includes(deferredSearchTerm));
}, [data, deferredSearchTerm]);
```

이렇게 하면 타이핑(입력) 반응 속도는 빠르게 유지하면서, 무거운 필터링 작업은 뒤로 미룰 수 있다.

**짧게 묶어보면:**

- `startTransition(() => setState())`: 상태 업데이트 자체를 미룬다.
- `useDeferredValue(value)`: 파생된 값(derived value)의 반영을 미룬다.

필요할 때 적절히 조합해서 쓰자. 단, 남용은 금물이다.

<br/>

### 테스트와 디버깅이 쉬운 훅

Hook 구조를 잘 잡으면 실제 컴포넌트를 렌더링하지 않고도 로직 대부분을 테스트할 수 있다.

- _도메인 로직을 UI와 분리하세요._
- _가능하면 Hook을 직접 테스트하세요._
- _Provider 로직은 별도의 Hook으로 분리해 명확하게 정리하세요._

```javascript
// Provider 로직 분리 예시
function useAuthProvider() {
  const [user, setUser] = useState(null);
  const login = async (credentials) => {
    /* ... */
  };
  const logout = () => {
    /* ... */
  };
  return { user, login, logout };
}

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const value = useAuthProvider();
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  return useContext(AuthContext);
}
```

먼 훗날 이 코드를 디버깅해야 할 때, 분명 과거의 자신에게 진심으로 고마워하게 될 것이다.

<br/>

### Hook 그 너머

React는 **데이터 중심(Data-first) 렌더링 패러다임**으로 진화하고 있다.
특히 서버 컴포넌트(Server Components)와 액션(Action) 패턴이 성숙해지며
이 흐름은 더 빨라지고 있다.
Solid.js 같은 세밀한 반응형(fine-grained reactivity)을 그대로 따르지는 않는다.
대신 비동기 데이터 처리와 서버 주도 UI(Server-driven UI)에 더 집중하는 방향을 택했다.

**알아두면 좋은 API:**

- `use()`: 렌더링 중 비동기 리소스 사용 (주로 서버 컴포넌트용)
- `useEffectEvent`: 안정적인 Effect 콜백
- `useActionState`: 워크플로우 형태의 비동기 상태 관리

React가 보여주는 흐름은 분명하다.
`useEffect`라는 **"맥가이버 칼(만능 도구)"** 하나에 과하게 의존하지 말고,
렌더링 주도 데이터 흐름(Render-driven Data Flows)으로 옮겨가라는 쪽이다.

<br/>

### Hooks

Hooks는 단순히 클래스 문법보다 **'조금 더 예쁜 API'**가 아니다.
**하나의 아키텍처 패턴**에 더 가깝다.

- _파생된 상태(Derived State)는 렌더링 중에 즉시 계산하세요._
- _Effect는 '진정한' 사이드 이펙트에만 사용하세요._
- _작고 명확한 목적을 가진 Hook들을 조립해 로직을 구성하세요._
- _동시성(Concurrency) 도구를 활용해 비동기 흐름을 매끄럽게 제어하세요._
- _클라이언트와 서버의 경계를 넘나드는 사고방식을 가지세요._

React가 진화하듯 Hook를 쓰는 방식도 같이 바뀌어야 한다.
2020년 방식이 틀렸다는 뜻은 아니다.
다만 React 18 이후에는 더 나은 도구가 분명히 생겼다.
이 패턴에 익숙해질수록 코드가 가벼워지는 걸 체감하게 된다.
