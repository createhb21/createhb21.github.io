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
---

### 서론

우리는 종종 `useEffect`를 React의 만능열쇠처럼 사용하곤 한다.

데이터 페칭부터 이벤트 리스너 등록, 상태 동기화까지 모든 사이드 이펙트를 `useEffect` 하나로 해결하려다 보면 코드는 점점 복잡해지고, 의도치 않은 렌더링 이슈나 **Race Condition**과 싸우게 된다.

**특히 키오스크 앱처럼 24시간 켜져 있어야 하는 장시간 동작 애플리케이션을 생각해보자.**
여기에 고객이 사용하는 기기가 **안드로이드 7 혹은 11과 같은 저성능 구형 기기**라면, 문제는 더 심각해진다.

이런 극한의 환경에서 과도한 `useEffect` 사용이 불러오는 '예상치 못한 사이드 이펙트'는 단순한 버그를 넘어 막대한 비용으로 이어진다. 메모리 누수나 불필요한 연산이 쌓여 기기가 멈추거나 동작이 느려진다면, 이는 곧 **치명적인 사용자 경험 저하**와 함께 **금전적 손실**로 직결된다.

React 18과 19를 거치며 플랫폼은 진화했다. 이제는 우리의 Hook 사용 습관도 그 흐름에 맞춰 **업데이트할 때**가 아닐까?

---

> _원문: [React has changed, your Hooks should too](https://allthingssmitty.com/2025/12/01/react-has-changed-your-hooks-should-too/) by Matt Smith_

---

### React는 변했다

React Hook이 등장한 지 몇 년이 지났지만, 여전히 많은 코드베이스는 과거의 방식에 머물러 있다. 약간의 `useState`, 남용되는 `useEffect`, 그리고 깊이 생각하지 않은 채 복사·붙여넣기 되는 패턴들... 우리 모두 한 번쯤은 그런 코드를 봤을 것이다.

하지만 Hook은 단순히 생명주기 메서드(Lifecycle Method)를 대체하기 위한 도구가 아니다. Hook은 더 표현력 있고 모듈화된 아키텍처를 만들기 위한 **디자인 시스템**이다.

React 18/19로 이어지는 동시성(Concurrent) 시대에 접어들면서, 데이터 처리 방식—특히 비동기 데이터 처리—이 완전히 새로워졌다. 이제 우리는 `Server Components`, `use()`, `Server Actions`, 그리고 프레임워크 수준에서 제공되는 데이터 로딩 기능을 사용할 수 있다. 클라이언트 컴포넌트 내부에서도 비동기를 다루는 새로운 접근법들이 생겨나고 있다.

이제 현대적인 Hook 패턴은 어떤 모습이어야 하는지, React가 개발자를 어떤 방향으로 이끌고 있는지, 그리고 우리가 자주 빠지는 함정들은 무엇인지 함께 살펴보자.

<br/>

### `useEffect`의 함정: 너무 많이, 너무 자주

`useEffect`는 여전히 가장 오용되고 있는 훅이다.
데이터 페칭, 파생된 값(derived values) 계산, 심지어 단순한 상태 변환 로직까지... 본래 **그 자리에 있어서는 안 될 로직들이 `useEffect`라는 '쓰레기통'으로 던져지곤 한다.**

컴포넌트가 마치 **"유령이 들린 것처럼"** 기이하게 동작하기 시작하는 시점이 바로 여기이다. 예상치 못한 타이밍에 리렌더링 되거나, 필요 이상으로 빈번하게 실행되는 것이다.

```javascript
useEffect(() => {
  fetchData();
}, [query]);
// 쿼리가 바뀔 때마다 실행됨.
// 하지만 새 값이 실질적으로 같은 경우(effectively the same)에도 불필요하게 실행될 수 있음.
```

이런 고통의 주원인은 **파생된 상태(Derived State)**와 **사이드 이펙트(Side Effect)**를 구분하지 않고 섞어 쓰는 데 있다.

React는 이 둘을 서로 전혀 다른 방식으로 취급한다.

<br/>

### React가 의도한 대로 Effect 사용하기

사실 React가 제시하는 기본 규칙은 놀라울 만큼 단순하다.

1. _**진짜 사이드 이펙트(Side Effect)에만 `useEffect`를 사용하세요.** (외부 세계와의 상호작용: 네트워크 요청, DOM 조작, 구독 등)_
2. _**그 외에는 렌더링 중에 계산하세요.** (Derived State)_

```javascript
// Good: useEffect 대신 useMemo 사용
const filteredData = useMemo(() => {
  return data.filter((item) => item.includes(query));
}, [data, query]);
```

꼭 Effect가 필요한 상황이라면, React의 `useEffectEvent`가 친구가 되어줄 것이다. 이것을 사용하면 의존성 배열(dependency array)을 지저분하게 만들지 않고도 Effect 내부에서 최신 props나 state에 접근할 수 있다.

```javascript
const handleSave = useEffectEvent(async () => {
  await saveToServer(formData);
});
```

`useEffect`를 작성하기 전에 스스로 물어보자.

- **이것이 외부 요인(네트워크, DOM, 구독)에 의해 주도되는가?**
- **아니면 렌더링 중에 계산할 수 있는가?**

후자라면, `useMemo`, `useCallback` 같은 도구나 프레임워크가 제공하는 기능을 사용하는 편이 컴포넌트를 훨씬 견고하게(robust) 만든다.

> Note: `useEffectEvent`를 의존성 배열 규칙을 회피하기 위한 치트키로 쓰지는 말자. 이는 오직 Effect 내부 로직을 최적화하기 위해 설계된 도구이기 때문이다.

<br/>

### 커스텀 훅: 단순 재사용이 아닌, 진정한 캡슐화

커스텀 훅은 단순히 중복 코드를 줄이는 게 아니다. **도메인 로직을 컴포넌트에서 뽑아내어, UI가 진짜 UI 역할에만 집중하게 만드는 것**이 핵심이다.

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

훨씬 깔끔하고 테스트하기도 좋다. 그리고 컴포넌트는 구현 세부 사항(implementation details)을 알 필요가 없어진다.

<br/>

### `useSyncExternalStore`: 구독 기반 상태 관리

React 18에 도입된 `useSyncExternalStore`는 구독(subscription), 티어링(tearing), 그리고 빈번한 업데이트와 관련된 수많은 버그를 말끔히 해결했다.

`matchMedia`, 스크롤 위치, 또는 서드파티 라이브러리의 스토어(Store)가 렌더링 시점마다 서로 다른 값(inconsistent values)를 반환하는 문제로 씨름해 본 적이 있는가? 이것이 바로 React가 그런 상황을 해결하기 위해 준비한 API이다.

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

> ⚠️ 주의: `useSyncExternalStore`는 동기적(synchronous) 업데이트를 보장한다. `useState`를 1:1로 대체하기 위한 기능이 아니다.

<br/>

### Transitions & Deferred Values: 더 부드러운 UI

사용자가 타이핑하거나 필터링할 때 앱이 버벅거린다면, React의 동시성 도구(Concurrency Tools)가 도움이 될 수 있다. 마법은 아니지만, React가 **'긴급한 업데이트'**와 **'비싼 업데이트'**의 우선순위를 조절하게 해 준다.

```javascript
const [searchTerm, setSearchTerm] = useState("");
const deferredSearchTerm = useDeferredValue(searchTerm);

const filtered = useMemo(() => {
  // 무거운 필터링 작업은 지연된 값을 사용
  return data.filter((item) => item.includes(deferredSearchTerm));
}, [data, deferredSearchTerm]);
```

이렇게 하면 타이핑(입력) 반응 속도는 빠르게 유지하면서, 무거운 필터링 작업은 뒤로 미룰 수 있다.

**간단 요약:**

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

### Hook 그 너머: 데이터 중심의 React 앱

React는 **데이터 중심(Data-first)의 렌더링 패러다임으로 진화하고 있다.** 특히 서버 컴포넌트(Server Components)와 액션(Action) 패턴이 성숙해짐에 따라 **이러한 흐름은 더욱 가속화되고 있다.** Solid.js 같은 세밀한 반응형(fine-grained reactivity)을 따르지는 않지만, 대신 비동기 데이터 처리와 서버 주도 UI(Server-driven UI)에 집중하는 방향을 택했다.

**알아두면 좋은 API:**

- `use()`: 렌더링 중 비동기 리소스 사용 (주로 서버 컴포넌트용)
- `useEffectEvent`: 안정적인 Effect 콜백
- `useActionState`: 워크플로우 형태의 비동기 상태 관리

**나아갈 방향은 명확하다.** React는 우리가 `useEffect`라는 **"맥가이버 칼(만능 도구)"에 대한 과도한 의존을 줄이고, 명료한 렌더링 주도 데이터 흐름(Render-driven Data Flows)을 따르기를 강력히 권장하고 있다.**

<br/>

### Hooks: 문법을 넘어선 아키텍처

Hooks는 단순히 클래스 문법보다 **'좀 더 예쁜 API'에 그치는게 아니다.** **이는 하나의 거대한 아키텍처 패턴이다.**

- _파생된 상태(Derived State)는 렌더링 중에 즉시 계산하세요._
- _Effect는 '진정한' 사이드 이펙트에만 사용하세요._
- _작고 명확한 목적을 가진 Hook들을 조립해 로직을 구성하세요._
- _동시성(Concurrency) 도구를 활용해 비동기 흐름을 매끄럽게 제어하세요._
- _클라이언트와 서버의 경계를 넘나드는 사고방식을 가지세요._

**React가 진화하듯, 우리의 Hook 작성 방식도 함께 진화해야 한다.** 2020년 스타일로 코드를 작성한다고 해서 틀린 것은 아니다. 하지만 React 18 이후의 버전들은 훨씬 더 강력한 도구 상자를 제공하고 있다. **또한 분명 우리가 이 새로운 패턴들에 익숙해진다면, 그 노력은 분명 더 큰 가치로 보답할 것이다.**
