---
layout: post
title: "Toss overlay-kit 소스코드 뜯어보기: 모달을 우아하게 다루는 구조의 비밀"
date: 2026-02-10 12:30:00 +0900
categories: [400-area]
tags: [react, overlay, modal, architecture, toss, open-source, frontend]
---

### 서론

Toss의 overlay-kit이라는 오픈소스를 처음 봤을 때, 솔직히 좀 놀랐다.

파일이 15개밖에 안 된다. 핵심 로직만 따지면 5~6개. 각 파일도 50~100줄 내외다. 그런데 이 작은 라이브러리가 해결하는 문제의 범위가 생각보다 넓다. 모달 열기/닫기는 기본이고, 순차적 모달 체이닝, 퇴장 애니메이션과 메모리 해제의 분리, 중복 오버레이 방지까지. React에서 오버레이를 다루면서 한 번쯤 겪어봤을 문제들을 꽤 우아하게 풀어놨다.

코드를 읽으면서 계속 든 생각은 이거였다. **"이걸 처음 설계한 사람은 어디서부터 생각을 시작했을까?"**

코드량은 적은데, 분명히 많은 고민을 한 흔적이 보인다. 이벤트 에미터를 왜 썼는지, Reducer를 왜 선택했는지, `useLayoutEffect`를 왜 써야만 했는지—하나하나가 "아, 여기서 이 선택을 안 했으면 이런 문제가 생겼겠구나"라는 역추적이 가능한 설계다.

이 글에서는 **"내가 이 라이브러리를 설계한 사람이라면?"**이라는 관점에서, 어떤 페인포인트에서 출발했고, 어떤 아이디어로 구조를 잡았고, 어디까지 고려한 건지를 추적해보려 한다.

---

## 출발점: "모달 하나 여는 게 왜 이렇게 복잡해?"

overlay-kit을 설계한 사람이 처음 느꼈을 불편함은 아마 이런 코드였을 거다.

```tsx
function SomeFeature() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <>
      <Button onClick={() => setIsOpen(true)}>열기</Button>
      <Dialog open={isOpen} onClose={() => setIsOpen(false)}>
        <DialogTitle>확인</DialogTitle>
        <DialogActions>
          <Button onClick={() => setIsOpen(false)}>닫기</Button>
        </DialogActions>
      </Dialog>
    </>
  );
}
```

이 코드 자체는 틀린 게 없다. 하지만 실무에서 모달이 하나만 있는 페이지는 거의 없다. 확인 모달, 에러 모달, 선택 모달, 결과 모달... 이런 게 한 컴포넌트에 3~4개씩 붙기 시작하면 `useState`가 줄줄이 늘어나고, 어디서 뭐가 열리고 닫히는지 추적이 안 된다.

그런데 이건 단순히 "코드가 지저분하다"는 수준의 문제가 아니다. 설계자가 진짜 해결하고 싶었던 건 좀 더 근본적인 것이었을 거다.

<br/>

## 첫 번째 문제의식: "오버레이의 상태를 컴포넌트가 왜 들고 있어야 하지?"

`useState`로 모달을 관리한다는 건, **그 모달의 생명주기가 부모 컴포넌트에 종속된다**는 뜻이다.

부모가 리마운트되면 모달 상태가 초기화된다. 다른 컴포넌트에서 그 모달을 열고 싶으면 상태를 끌어올려야 한다. 모달이 열려있는지 확인하려면 해당 `isOpen` 상태에 접근할 수 있어야 한다. 이 모든 게 **"컴포넌트가 오버레이 상태를 소유하고 있기 때문"**에 발생하는 문제다.

여기서 아이디어가 하나 나온다.

> "오버레이 상태를 컴포넌트에서 빼서, 중앙에서 관리하면 되지 않나?"

이건 전역 상태 관리(Redux, Zustand 등)로도 할 수 있다. 하지만 설계자는 한 발 더 나아간 것 같다. 단순히 상태를 중앙화하는 게 아니라, **오버레이를 여는 행위 자체를 명령형 API로 만들자**는 발상.

```tsx
// 이상적인 형태를 먼저 상상했을 것이다
overlay.open(({ isOpen, close }) => (
  <Dialog open={isOpen} onClose={close}>
    <DialogTitle>확인</DialogTitle>
  </Dialog>
));
```

`useState` 없이, `import` 한 줄로, 어디서든 모달을 열 수 있다. 상태 선언도 없고, 핸들러 연결도 없다. **"이 모달을 열어"**라는 명령 하나가 전부다.

이 API를 실현하려면 어떤 구조가 필요할까? overlay-kit의 아키텍처는 이 질문에 대한 답이다.

---

## 구조의 핵심: 명령형 API와 선언형 렌더링을 어떻게 연결할 것인가

`overlay.open()`은 React 바깥의 일반 함수다. 하지만 실제 모달을 렌더링하는 건 React의 컴포넌트 트리 안이다. 이 두 세계를 연결해야 한다.

overlay-kit은 이걸 **이벤트 에미터**로 해결한다.

```
overlay.open() → [Event Emitter] → OverlayProvider(useReducer) → 렌더링
```

전체 파일 구조를 보면 이 설계 의도가 명확하다:

```
packages/src/
├── event.ts                           # overlay.open/close → 이벤트 발행
├── utils/
│   ├── emitter.ts                     # 경량 이벤트 에미터
│   └── create-use-external-events.ts  # 에미터 ↔ React 훅 브릿지
├── context/
│   ├── reducer.ts                     # 오버레이 상태 머신
│   └── provider/
│       ├── index.tsx                  # OverlayProvider (상태 + 렌더링)
│       └── content-overlay-controller.tsx  # 개별 오버레이 래퍼
└── utils/
    ├── create-safe-context.ts         # Symbol 기반 안전한 Context
    └── create-overlay-context.tsx     # 싱글톤 생성 + 팩토리
```

각 파일이 하나의 역할만 담당한다. 에미터는 메시지를 전달하고, 브릿지는 에미터와 React를 연결하고, Reducer는 상태를 관리하고, Provider는 렌더링을 담당한다.

이제 각 레이어를 하나씩 파고들어보자.

---

## 이벤트 에미터: React 바깥에서 메시지를 보내는 방법

이벤트 에미터(Event Emitter)라는 개념이 낯설 수 있으니 간단히 설명하고 넘어가자.

이벤트 에미터는 **"누군가 메시지를 보내면, 그 메시지를 듣고 있던 사람이 반응한다"**는 패턴이다. Node.js의 `EventEmitter`를 써봤다면 익숙할 텐데, 브라우저의 `addEventListener`와도 비슷한 개념이다. 핵심 API는 세 가지뿐이다:

- **`on(type, handler)`** — "이 타입의 메시지가 오면 이 함수를 실행해줘" (구독)
- **`off(type, handler)`** — "더 이상 듣지 않을게" (구독 해제)
- **`emit(type, data)`** — "이 타입의 메시지를 보낸다" (발행)

이게 왜 필요한가? `overlay.open()`은 React 바깥의 일반 함수이고, 모달을 실제로 렌더링하는 `OverlayProvider`는 React 안에 있다. 이 둘 사이에 직접적인 참조가 없다. 이벤트 에미터는 이 두 세계를 연결하는 **메시지 버스** 역할을 한다. "모달 열어!"라는 메시지를 에미터에 보내면, 그걸 구독하고 있던 Provider가 받아서 처리하는 구조다.

overlay-kit은 이 이벤트 에미터를 직접 구현했다. [Mitt](https://github.com/developit/mitt)이라는 유명한 초경량 에미터 라이브러리가 있는데(Preact를 만든 Jason Miller의 라이브러리, gzip 기준 200바이트), overlay-kit의 에미터는 이 Mitt의 구현 방식을 거의 그대로 따른다.

```ts
// utils/emitter.ts
export function createEmitter<Events extends Record<EventType, unknown>>() {
  const all: EventHandlerMap<Events> = new Map();

  return {
    on(type, handler) {
      const handlers = all.get(type);
      if (handlers) handlers.push(handler);
      else all.set(type, [handler]);
    },
    off(type, handler) {
      const handlers = all.get(type);
      if (handlers) {
        handlers.splice(handlers.indexOf(handler) >>> 0, 1);
      }
    },
    emit(type, evt) {
      const handlers = all.get(type);
      if (handlers) {
        handlers.slice().forEach((handler) => handler(evt));
      }
    },
  };
}
```

코드 자체는 단순한데, 디테일이 꼼꼼하다.

**`.slice()` 후 순회.** `emit` 안에서 핸들러 배열을 복사한 뒤 iterate한다. 왜? emit 도중에 핸들러가 자기 자신을 제거하는 경우를 대비한 거다. 예를 들어 "한 번만 실행하고 자동 해제"되는 핸들러가 있다면, emit 중에 `off`가 호출되면서 원본 배열이 변한다. 복사본으로 순회하면 이 문제가 없다. 실제 테스트 코드에서 이 시나리오를 명시적으로 검증하고 있다.

**`>>> 0` 비트 연산.** `indexOf`가 `-1`을 반환하면, unsigned right shift로 `4294967295`가 된다. `splice(4294967295, 1)`은 사실상 no-op이다. Mitt에서 가져온 관용적 패턴인데, 존재하지 않는 핸들러를 `off`해도 에러가 나지 않는 안전장치다.

이 에미터는 **모듈 스코프에서 딱 하나만** 생성된다. React의 라이프사이클과 완전히 독립적이다. 그래서 컴포넌트 바깥의 유틸 함수, API 응답 핸들러, 심지어 React 외부 코드에서도 `overlay.open()`을 자유롭게 호출할 수 있다.

---

## 에미터 ↔ React 브릿지: 여기서 useLayoutEffect를 쓴 이유

에미터가 React 바깥에 있다면, React 안의 `OverlayProvider`는 이벤트를 어떻게 수신할까? 이 연결 고리가 `createUseExternalEvents`다.

```ts
// utils/create-use-external-events.ts
const emitter = createEmitter(); // 글로벌 싱글톤

export function createUseExternalEvents<EventHandlers>(prefix: string) {
  function useExternalEvents(events: EventHandlers) {
    useLayoutEffect(() => {
      Object.entries(events).forEach(([key, fn]) => {
        emitter.on(`${prefix}:${key}`, fn);
      });
      return () => {
        Object.entries(events).forEach(([key, fn]) => {
          emitter.off(`${prefix}:${key}`, fn);
        });
      };
    });
  }

  function createEvent(event) {
    return (payload) => emitter.emit(`${prefix}:${event}`, payload);
  }

  return [useExternalEvents, createEvent] as const;
}
```

반환값 두 가지:

- **`useExternalEvents`** — React 훅. OverlayProvider 안에서 호출되어 에미터에 핸들러를 등록한다.
- **`createEvent`** — 일반 함수. `overlay.open()` 등에서 호출되어 에미터에 이벤트를 발행한다.

`prefix`는 각 overlay context마다 고유한 랜덤 ID가 붙는다. 글로벌 에미터 하나를 공유하면서도 네임스페이스 충돌이 없다.

### 여기서 중요한 질문: 왜 `useLayoutEffect`일까?

이 부분이 overlay-kit 설계에서 가장 세심한 결정 중 하나라고 생각한다. `useEffect`가 아니라 `useLayoutEffect`를 썼다. 이 차이가 왜 중요한지, `useEffect`를 썼다면 어떤 버그가 발생하는지 따져보자.

먼저 React의 라이프사이클을 정확히 이해해야 한다:

```
[Render Phase] → [Commit Phase] → [useLayoutEffect 동기 실행] → [Paint] → [useEffect 비동기 실행]
```

`useLayoutEffect`는 DOM이 변경된 직후, **브라우저가 화면을 그리기 전에 동기적으로** 실행된다. 반면 `useEffect`는 브라우저가 화면을 그린 **후에 비동기적으로** 실행된다.

overlay-kit의 `OverlayProvider`가 처음 마운트되는 상황을 생각해보자:

```
1. OverlayProvider 렌더링
2. useLayoutEffect → 에미터에 핸들러 등록 (동기)
3. 브라우저 Paint
4. useEffect (만약 여기였다면 → 에미터에 핸들러 등록)
```

**만약 `useEffect`를 썼다면?** Provider가 렌더링되고 Paint된 후에야 핸들러가 등록된다. 그 사이에 `overlay.open()`이 호출되면? 에미터는 이벤트를 발행하지만, **아직 핸들러가 없다.** 이벤트가 허공으로 사라진다. 모달이 안 열린다.

"그게 실제로 일어나나?"라고 생각할 수 있다. 일어난다. 특히 이런 패턴에서:

```tsx
function App() {
  useEffect(() => {
    // 앱 초기화 시 바로 모달을 여는 케이스
    overlay.open(({ isOpen, close }) => (
      <WelcomeDialog isOpen={isOpen} onClose={close} />
    ));
  }, []);

  return (
    <OverlayProvider>
      <MainContent />
    </OverlayProvider>
  );
}
```

`App`의 `useEffect`와 `OverlayProvider`의 `useEffect`는 **같은 타이밍**에 스케줄링된다. React는 부모 → 자식 순서가 아니라, 자식 → 부모 순서로 `useEffect`를 실행한다(cleanup은 부모→자식이지만, setup은 자식→부모). 그래서 순서가 꼬일 수 있다.

더 현실적인 시나리오도 있다. 사용자 이벤트 핸들러에서 `overlay.open()`을 호출하는 건 대부분 안전하지만, **StrictMode에서의 더블 실행**, **Suspense 경계에서의 재마운트**, **Fast Refresh 후의 타이밍** 같은 엣지 케이스에서 `useEffect`의 비동기 특성이 문제를 일으킬 수 있다.

`useLayoutEffect`를 쓰면 이 모든 게 해결된다. Commit Phase 직후, Paint 전에 동기적으로 핸들러가 등록되니까, `overlay.open()`이 호출되는 시점에는 **반드시** 핸들러가 준비되어 있다.

하지만 `useLayoutEffect`에도 비용은 있다. **동기 실행이라 Paint를 블로킹한다.** 핸들러 등록 자체는 Map에 함수 참조를 넣는 것이므로 O(1)에 가깝지만, 이걸 알고도 선택한 거다. "Paint가 미세하게 밀리는 것"보다 "이벤트가 유실되는 것"이 훨씬 치명적이니까.

그리고 한 가지 더—`useLayoutEffect`는 SSR 환경에서 경고를 발생시킨다. overlay-kit은 이것도 대비해서, 내부적으로 `isClientEnvironment()` 체크를 한다:

```ts
function isClientEnvironment() {
  const isBrowser = typeof document !== 'undefined';
  const isReactNative = typeof navigator !== 'undefined'
    && navigator.product === 'ReactNative';
  return isBrowser || isReactNative;
}
```

브라우저 또는 React Native 환경에서만 `useLayoutEffect`를 실행하고, 서버에서는 건너뛴다. 빌드 타임에 `"use client"` 배너까지 주입해서 Next.js App Router와의 호환성도 챙긴다. 이런 디테일 하나하나가 "어, 이거 SSR에서 안 돌아가는데요?"라는 이슈를 미리 막아두는 것이다.

---

## Reducer: 왜 useState가 아니라 useReducer인가

overlay-kit의 상태 관리는 `useReducer` 기반이다. 이것이 이 라이브러리의 핵심 설계 결정이고, `useState`와 결정적으로 다른 지점이다.

### 상태 구조

```ts
type OverlayItem = {
  id: string;
  componentKey: string; // React key (리마운트 제어용)
  isOpen: boolean; // 시각적 열림/닫힘 상태
  isMounted: boolean; // 마운트 여부 (애니메이션용)
  controller: OverlayControllerComponent;
};

type OverlayData = {
  current: string | null; // 최상위 오버레이 ID
  overlayOrderList: string[]; // 오버레이 스택 (순서 보장)
  overlayData: Record<string, OverlayItem>;
};
```

`overlayOrderList`가 배열이라는 점에 주목하자. 객체가 아니라 배열이다. 오버레이의 **쌓이는 순서(z-order)**가 중요하기 때문이다. 나중에 열린 오버레이가 배열 뒤쪽에 위치하고, 이것이 곧 렌더링 순서가 된다.

### 여기서 또 질문: 왜 useState 여러 개가 아니라 useReducer 하나인가?

`useState`로도 비슷하게 만들 수 있다. `overlayList`, `currentId`, `overlayData`를 각각 `useState`로 관리하면. 하지만 문제가 있다.

모달을 하나 닫는 동작을 생각해보자. 이때 해야 할 일이 세 가지다:

1. 해당 오버레이의 `isOpen`을 `false`로 변경
2. `current`를 다음 최상위 오버레이로 갱신
3. (필요하다면) 다른 오버레이의 상태도 조정

`useState`라면 이 세 가지가 각각 독립된 `setState` 호출이다. React 18의 automatic batching 덕분에 대부분 한 번에 처리되지만, **상태 간 정합성**을 보장하기가 어렵다. A 상태를 업데이트할 때 B 상태의 "현재 값"이 필요한데, 클로저에 잡힌 값이 이미 stale일 수 있다.

`useReducer`는 이걸 원천적으로 해결한다. **하나의 dispatch가 하나의 상태 전이**를 나타내고, reducer 함수 안에서 전체 상태에 접근할 수 있으니까 정합성이 깨질 여지가 없다.

### 중복 방지의 핵심: ADD 액션

```ts
case 'ADD': {
  // 1. 이미 존재하지만 닫힌 상태 → 재오픈
  if (state.overlayData[id] != null && !state.overlayData[id].isOpen) {
    return { /* isOpen: true로 변경, 스택 최상위로 이동 */ };
  }

  // 2. 이미 존재하고 열린 상태 → 에러!
  if (isExisted && state.overlayData[id].isOpen) {
    throw new Error(
      `You can't open the multiple overlays with the same overlayId(${id}).`
    );
  }

  // 3. 새로운 오버레이 → 정상 추가
  return { /* 스택에 추가 */ };
}
```

이 코드가 **중복 모달 문제를 구조적으로 해결하는 핵심**이다.

이미 열려있는 ID로 `ADD`가 들어오면 에러를 던진다. 화면을 그리기도 전에, 데이터 레벨에서 차단한다. 사용자가 버튼을 연타하든, CPU가 잠시 멈췄다 돌아오든, 동일 ID의 오버레이는 물리적으로 두 개가 될 수 없다.

이건 데이터베이스의 Unique Constraint와 같은 개념이다. INSERT 시점에 중복을 체크하는 것처럼, 오버레이 추가 시점에 ID 중복을 체크한다.

### 스택 최상위 결정 알고리즘

오버레이 하나가 닫힐 때 "다음으로 보여줄 오버레이"를 결정하는 로직도 재미있다:

```ts
const determineCurrentOverlayId = (overlayOrderList, overlayData, targetId) => {
  const openedList = overlayOrderList.filter((id) => overlayData[id].isOpen);
  const targetIndex = openedList.findIndex((id) => id === targetId);

  // 최상위를 닫으면 → 바로 아래 것이 current
  // 중간 것을 닫으면 → 최상위가 그대로 current
  return targetIndex === openedList.length - 1
    ? (openedList[targetIndex - 1] ?? null)
    : openedList[openedList.length - 1];
};
```

모달 A, B, C가 순서대로 쌓여있을 때, C를 닫으면 B가 current가 되고, B를 닫으면 C가 그대로 current다. 중간 레이어를 닫아도 최상위가 흔들리지 않는 구조다.

---

## 2단계 마운트 패턴: 애니메이션을 위한 영리한 트릭

overlay-kit 소스를 읽으면서 "아, 이건 생각 못 했을 수도 있겠다"고 느낀 부분이다.

`ContentOverlayController`의 구현을 보자:

```tsx
const ContentOverlayController = memo(
  ({ isOpen, overlayId, controller: Controller, overlayDispatch }) => {
    useEffect(() => {
      requestAnimationFrame(() => {
        overlayDispatch({ type: "OPEN", overlayId });
      });
    }, []);

    return (
      <Controller
        isOpen={isOpen}
        close={() => overlayDispatch({ type: "CLOSE", overlayId })}
        unmount={() => overlayDispatch({ type: "REMOVE", overlayId })}
      />
    );
  },
);
```

이 코드가 하는 일:

1. **첫 번째 렌더**: `isOpen: false`로 마운트된다. 컨트롤러 컴포넌트는 `isOpen=false`를 받는다.
2. **requestAnimationFrame 후**: `OPEN` 디스패치로 `isOpen: true`가 된다.
3. **두 번째 렌더**: 컨트롤러가 `isOpen=true`를 받는다.

왜 이렇게 할까? **CSS 트랜지션과 Framer Motion 같은 애니메이션 라이브러리를 위해서다.**

만약 처음부터 `isOpen: true`로 마운트하면, 애니메이션의 "시작 상태(from)"가 없다. `false → true`라는 상태 전환이 있어야 `AnimatePresence`나 CSS `transition`이 동작한다. overlay-kit은 이 전환을 `requestAnimationFrame` 한 프레임 딜레이로 보장한다.

설계자의 입장에서 생각해보면 이건 꽤 고민스러운 지점이었을 거다. "첫 렌더에서 바로 열면 안 되나?"라는 단순한 질문에 "안 돼, CSS 트랜지션이 먹히려면 초기 상태가 먼저 렌더되어야 해"라는 답을 내렸고, 그걸 `requestAnimationFrame`이라는 브라우저 API 한 줄로 해결한 거다.

닫힘 → 재오픈 시에도 같은 패턴이 적용된다. Provider 내부에서 이전 상태와 현재 상태를 비교해서, `isOpen`이 `false → true`로 바뀐 오버레이에 대해 다시 `requestAnimationFrame`으로 `OPEN`을 디스패치한다:

```tsx
// OverlayProvider 내부
if (prevOverlayState.current !== overlayState) {
  overlayState.overlayOrderList.forEach((overlayId) => {
    const prev = prevOverlayState.current.overlayData[overlayId];
    const curr = overlayState.overlayData[overlayId];
    if (prev?.isMounted && !prev.isOpen && curr.isOpen) {
      requestAnimationFrame(() => {
        overlayDispatch({ type: "OPEN", overlayId });
      });
    }
  });
}
```

---

## close vs unmount: "닫는 것"과 "치우는 것"은 다르다

overlay-kit을 설계한 사람이 가장 심사숙고했을 것 같은 부분이다. `close`와 `unmount`를 왜 분리했을까?

모달을 닫을 때 어떤 일이 벌어지는지 생각해보면 답이 나온다. 사용자가 닫기 버튼을 누르면 모달이 fade out되면서 사라진다. 이 "사라지는 애니메이션"이 재생되는 동안, 컴포넌트는 **아직 DOM에 존재해야 한다.** 존재하지 않는 컴포넌트는 애니메이션을 재생할 수 없으니까.

| 동작       | `close()`            | `unmount()`        |
| ---------- | -------------------- | ------------------ |
| `isOpen`   | `false`로 변경       | -                  |
| DOM 존재   | 유지됨               | 제거됨             |
| 애니메이션 | 퇴장 애니메이션 가능 | 즉시 사라짐        |
| 재오픈     | 가능 (같은 인스턴스) | 새 인스턴스로 생성 |
| 메모리     | 유지됨               | 해제됨             |

실제 사용 패턴:

```tsx
overlay.open(({ isOpen, close, unmount }) => (
  <Modal
    isOpen={isOpen}
    onClose={close} // 닫기 → 퇴장 애니메이션 시작
    onExitComplete={unmount} // 애니메이션 끝 → DOM에서 제거
  />
));
```

`close()`가 호출되면 `isOpen`이 `false`가 되면서 퇴장 애니메이션이 시작된다. 하지만 컴포넌트는 DOM에 여전히 존재한다. `AnimatePresence`의 `onExitComplete`가 호출되는 시점에 `unmount()`를 호출하면, 그때야 비로소 Reducer에서 `REMOVE` 액션이 처리되어 컴포넌트가 완전히 제거된다.

만약 이 분리가 없었다면? 두 가지 중 하나를 선택해야 한다:
- `close`와 동시에 DOM에서 제거 → 퇴장 애니메이션이 잘린다
- `setTimeout`으로 제거를 지연 → 디바이스 성능에 따라 타이밍이 안 맞는다 (300ms? 500ms? 어떤 값이든 "정확한" 타이밍은 아니다)

overlay-kit은 이걸 **이벤트 기반으로** 해결했다. "애니메이션이 실제로 끝났어"라는 콜백을 받아서 처리하니까, 디바이스 성능에 관계없이 항상 정확하다. `setTimeout(unmount, 300)` 같은 매직 넘버가 없다.

이건 설계자가 "모달 라이브러리는 애니메이션 라이브러리와 함께 쓰인다"는 현실을 정확히 인식하고 있었다는 증거다.

---

## Promise 기반 비동기 오버레이: 가장 영리한 아이디어

이 부분은 overlay-kit에서 내가 가장 감탄한 기능이다. 설계자가 "오버레이를 명령형으로 열 수 있게 했다"에서 한 발 더 나아가서, **"오버레이의 결과를 Promise로 받을 수 있게 하면 어떨까?"**라고 생각한 거다.

### 순차적 모달의 고전적 난제

"확인 다이얼로그에서 '네'를 누르면 → 목록을 보여주고 → 선택하면 → 완료 화면을 보여준다."

이런 순차적 흐름을 기존 `useState` 방식으로 구현하면:

```tsx
const [showConfirm, setShowConfirm] = useState(false);
const [showList, setShowList] = useState(false);
const [showDone, setShowDone] = useState(false);
const [selected, setSelected] = useState(null);

const handleConfirm = () => {
  setShowConfirm(false);
  fetchList().then(() => setShowList(true));
};

const handleSelect = (item) => {
  setSelected(item);
  setShowList(false);
  submit(item).then(() => setShowDone(true));
};
```

상태가 4개, 핸들러가 2개, 그리고 "어떤 순서로 뭐가 열리고 닫히는지"가 코드 여기저기에 분산되어 있다. 비즈니스 로직(순차 흐름)이 상태 관리 코드에 파묻혀버린다.

### overlay-kit: async/await으로 비즈니스 흐름 그대로

```tsx
async function handleFlow() {
  // 1단계: 확인
  const confirmed = await overlay.openAsync<boolean>(
    ({ isOpen, close }) => (
      <ConfirmDialog
        isOpen={isOpen}
        onNo={() => close(false)}
        onYes={() => close(true)}
      />
    ),
  );

  if (!confirmed) return;

  // 2단계: 목록에서 선택
  const selected = await overlay.openAsync<Item | null>(
    ({ isOpen, close, unmount }) => (
      <ListModal
        isOpen={isOpen}
        onClose={() => close(null)}
        onSelect={close}
        onExited={unmount}
      />
    ),
  );

  if (!selected) return;

  // 3단계: 처리 후 완료
  await submit(selected);
  await overlay.openAsync(({ isOpen, close, unmount }) => (
    <DoneModal isOpen={isOpen} onClose={() => close(null)} onExited={unmount} />
  ));
}
```

"확인 → 선택 → 완료"라는 비즈니스 흐름이 **코드의 흐름과 1:1로 대응**한다. 위에서 아래로 읽으면 그게 곧 사용자 경험이다.

### 내부 구현: Promise로 콜백을 감싸는 트릭

```ts
const openAsync = <T>(controller, options?) => {
  return new Promise<T>((resolve, reject) => {
    open((overlayProps) => {
      const wrappedClose = (param: T) => {
        resolve(param); // Promise 해소
        overlayProps.close(); // 시각적 닫기
      };
      return controller({ ...overlayProps, close: wrappedClose, reject });
    }, options);
  });
};
```

아이디어가 깔끔하다. `open()`을 호출하되, 컨트롤러에 전달되는 `close`를 감싸서 Promise의 `resolve`와 연결한다. 사용자가 모달에서 `close(true)`를 호출하면, 그 `true`가 `await`의 반환값이 된다.

타입 시스템도 이걸 정확히 지원한다:

```ts
type OverlayControllerProps = {
  close: () => void; // 일반: 값 없이 닫기
};

type OverlayAsyncControllerProps<T> = {
  close: (param: T) => void; // 비동기: 타입된 값과 함께 닫기
  reject: (reason?: unknown) => void;
};
```

`openAsync<boolean>(...)`이면 `close(true)` 또는 `close(false)`만 허용된다. 타입 안전성까지 챙긴 설계다.

이 기능을 설계하려면 **"모달의 결과는 결국 콜백으로 돌아온다"**와 **"Promise는 콜백을 감싸는 가장 표준적인 방법이다"**라는 두 가지 인사이트가 결합되어야 한다. 각각은 당연한 사실인데, 이걸 조합해서 `overlay.openAsync`라는 API로 만든 건 꽤 영리하다.

---

## 고정 ID: "같은 의미의 오버레이는 세상에 하나만 존재해야 한다"

overlay-kit의 `open()`은 기본적으로 매번 랜덤 ID를 생성한다:

```ts
const overlayId = options?.overlayId ?? randomId();
```

하지만 `options.overlayId`를 지정하면 그 ID가 고정된다. 같은 ID로 두 번 열려고 하면 Reducer에서 에러를 던진다.

이걸 활용하면:

```ts
const OVERLAY_IDS = {
  CONFIRM: "overlay/confirm",
  ALERT: "overlay/alert",
  SETTINGS: "overlay/settings",
} as const;

overlay.open(controller, { overlayId: OVERLAY_IDS.CONFIRM });
```

동일한 ID로는 절대 두 개의 오버레이가 동시에 존재할 수 없다.

이건 설계자가 **"중복 오버레이 문제를 라이브러리 사용자에게 떠넘기지 않겠다"**는 의지를 보여주는 부분이다. ID를 비즈니스 로직 단위로 고정시키면, 디바운싱이나 플래그 체크 같은 임시방편 없이도 중복이 원천 차단된다.

---

## 격리된 오버레이 스코프: 어디까지 고려한 건가

overlay-kit의 기본 사용법만 보면 싱글톤이다. `overlay` 객체가 모듈 스코프에서 딱 하나 만들어진다:

```ts
// 기본 싱글톤
export const { overlay, OverlayProvider, useCurrentOverlay, useOverlayData }
  = createOverlayProvider();
```

하지만 소스코드를 더 보면, `experimental_createOverlayContext()`라는 팩토리 함수가 있다:

```ts
export function experimental_createOverlayContext() {
  return createOverlayProvider();
}
```

이걸 호출할 때마다 **완전히 독립된 오버레이 시스템**이 생성된다. 자체 에미터 prefix, 자체 React Context, 자체 overlay 컨트롤러. 서로 간섭하지 않는다.

이 기능의 존재가 시사하는 건, 설계자가 이런 시나리오까지 고려했다는 거다:

- 마이크로 프론트엔드에서 각 모듈이 독립된 오버레이 스택을 가져야 하는 경우
- 알림(notification)과 모달(dialog)을 분리된 레이어로 관리하고 싶은 경우
- 테스트 환경에서 격리된 오버레이 인스턴스가 필요한 경우

아직 `experimental_` 접두사가 붙어있어서 안정화 전이지만, 이걸 미리 설계해둔 건 확장성 면에서 상당히 사려 깊은 판단이다.

---

## OverlayProvider의 렌더링 전략

마지막으로, `OverlayProvider`가 오버레이를 어떻게 렌더링하는지 보자.

```tsx
function OverlayProvider({ children }) {
  const [overlayState, dispatch] = useReducer(overlayReducer, initialState);

  useOverlayEvent({
    open: ({ controller, overlayId, componentKey }) =>
      dispatch({
        type: "ADD",
        overlay: { id: overlayId, componentKey, isOpen: false, controller },
      }),
    close: (id) => dispatch({ type: "CLOSE", overlayId: id }),
    unmount: (id) => dispatch({ type: "REMOVE", overlayId: id }),
    closeAll: () => dispatch({ type: "CLOSE_ALL" }),
    unmountAll: () => dispatch({ type: "REMOVE_ALL" }),
  });

  return (
    <OverlayContextProvider value={overlayState}>
      {children}
      {overlayState.overlayOrderList.map((item) => {
        const { id, componentKey, isOpen, controller } =
          overlayState.overlayData[item];
        return (
          <ContentOverlayController
            key={componentKey}
            isOpen={isOpen}
            controller={controller}
            overlayId={id}
          />
        );
      })}
    </OverlayContextProvider>
  );
}
```

세 가지 디테일이 보인다.

**`{children}` 뒤에 오버레이가 렌더링된다.** DOM 순서상 오버레이가 일반 콘텐츠보다 항상 뒤에 위치한다. z-index 없이도 자연스럽게 위에 쌓인다.

**`key`에 `componentKey`를 쓴다.** `overlayId`가 아니라 매번 새로 생성되는 `componentKey`다. 같은 `overlayId`로 unmount 후 다시 open하면 완전히 새로운 React 컴포넌트 인스턴스가 생성된다. 이전 상태가 남아있는 문제(stale state)를 원천 차단한다.

**`ContentOverlayController`가 `memo`로 감싸져 있다.** 전체 오버레이 목록이 상태 변경 때마다 다시 렌더링되는데, `memo` 덕분에 개별 오버레이는 자신의 props가 바뀔 때만 리렌더된다. 오버레이가 5개 쌓여있어도, 하나를 닫을 때 나머지 4개는 리렌더되지 않는다.

---

## 이 설계에서 배울 수 있는 것

overlay-kit의 소스코드를 전부 읽고 나서, 이 라이브러리를 설계한 사람의 사고 흐름을 역추적해보면 이렇다:

1. **페인포인트 인식**: "오버레이 상태를 컴포넌트가 들고 있으면 안 되겠다."
2. **핵심 아이디어**: "명령형으로 열고, 선언형으로 렌더링하자."
3. **연결 고리 선택**: "React 바깥의 명령을 React 안으로 전달하려면 이벤트 에미터."
4. **상태 관리 결정**: "정합성을 보장하려면 useReducer."
5. **타이밍 보장**: "핸들러 등록이 Paint 전에 끝나야 하니까 useLayoutEffect."
6. **애니메이션 지원**: "close와 unmount를 분리하고, 2단계 마운트 패턴을 적용."
7. **비동기 제어**: "모달의 결과를 Promise로 반환하면 순차 흐름이 자연스러워진다."
8. **중복 방지**: "ID를 고정하면 Reducer 레벨에서 중복을 차단할 수 있다."
9. **확장성**: "싱글톤이 기본이되, 격리된 스코프도 만들 수 있게."

각 단계가 이전 단계의 문제를 해결하면서 자연스럽게 다음 단계로 이어진다. 15개 파일에 이 모든 게 담겨있다는 게 놀랍다.

실무에서 비슷한 문제를 만났을 때, 이 라이브러리를 직접 쓸 수도 있고, 이 설계 패턴을 참고해서 자체 시스템을 만들 수도 있다. 어느 쪽이든, **"오버레이 상태를 누가 소유할 것인가"**와 **"명령형 호출과 선언형 렌더링을 어떻게 연결할 것인가"**라는 두 질문은 여전히 유효하다.

overlay-kit은 그 질문에 대한 상당히 우아한 답 중 하나다.

---

### 참고

- [overlay-kit GitHub](https://github.com/toss/overlay-kit) — Toss 오픈소스 라이브러리
- [overlay-kit 공식 문서](https://overlay-kit.slash.page/) — 사용법 및 예제
