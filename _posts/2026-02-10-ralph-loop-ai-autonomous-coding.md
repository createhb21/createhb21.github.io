---
layout: post
title: "Ralph Loop: Claude Code로 자율 코딩 루프 돌려본 후기"
date: 2026-02-10 11:00:00 +0900
categories: [400-area]
tags: [ai, claude-code, ralph-loop, automation, dx, productivity]
---

### 서론

요즘 AI 코딩 도구를 안 쓰는 개발자가 오히려 드물다.

Antigravity, Cursor, Claude Code... 도구 자체는 이미 일상이 됐는데, 쓰다 보면 한 가지 병목이 반복된다. **사람이 계속 프롬프트를 넣어줘야 한다는 것.**

"이거 구현해줘" → 결과 확인 → "이것도 해줘" → 확인 → "테스트 깨졌어, 고쳐줘" → ...

이 루프를 하루에 수십 번씩 반복하다 보면, AI가 일을 해주는 건지 내가 AI한테 일을 시키느라 일하는 건지 헷갈릴 때가 있다.

**Ralph Loop**은 이 병목을 정면으로 해결하려는 기법이다. AI한테 같은 명령을 무한 반복 시켜서, 사람 개입 없이 알아서 계획 → 구현 → 테스트 → 커밋까지 돌아가게 만든다.

직접 세팅해보고 돌려본 경험을 정리해본다.

---

## Ralph Loop이 뭔데?

핵심은 놀라울 정도로 단순하다.

```bash
while true; do
  cat PROMPT.md | claude -p --dangerously-skip-permissions
done
```

이게 전부다. Claude Code CLI에 같은 프롬프트를 무한으로 넣는 루프.

하지만 여기에 몇 가지 영리한 장치가 붙는다:

1. **진행 상황은 파일에 기록한다.** 대화 컨텍스트가 아닌 `IMPLEMENTATION_PLAN.md` 파일에 할 일 목록과 진행 상태를 남긴다.
2. **컨텍스트가 차면 새 세션이 시작된다.** 하지만 파일을 읽으면서 이전 작업을 이어받는다.
3. **매 반복마다 git commit + push.** 코드 변경 내역이 히스토리에 남으니 추적도 가능하다.

```
[세션 1] 파일 읽기 → 작업 → 기록 → 컨텍스트 꽉 참 → 종료
            ↓
[세션 2] 파일 읽기 → 이어서 작업 → 기록 → 종료
            ↓
[세션 3] ...무한 반복
```

이름은 심슨 가족의 **랄프 위검**(Ralph Wiggum)에서 따왔다. 멍청하지만 끈질기고 낙관적인 캐릭터처럼, AI도 같은 명령을 반복하면서 조금씩 발전시킨다는 의미다. Claude Code 팀의 보리스 체르니(Boris Cherny)가 이 기법의 가치를 공식으로 인정하면서 업계 용어가 됐다.

<br/>

## 세팅하기

[ralph-playbook](https://github.com/ClaytonFarr/ralph-playbook)이라는 오픈소스 구현체가 있다. Clayton Farr라는 개발자가 Geoff Huntley의 Ralph 방법론을 Bash 스크립트로 깔끔하게 정리해놓은 저장소다.

### 필요한 것

- Claude Code CLI
- `jq` (JSON 처리용)
- git 저장소

### 설치

```bash
# 템플릿 클론
git clone https://github.com/ClaytonFarr/ralph-playbook.git ~/ralph-playbook

# 내 프로젝트에 파일 복사
cd /path/to/my-project
cp ~/ralph-playbook/files/loop.sh .
cp ~/ralph-playbook/files/PROMPT_build.md .
cp ~/ralph-playbook/files/PROMPT_plan.md .
cp ~/ralph-playbook/files/AGENTS.md .
cp ~/ralph-playbook/files/IMPLEMENTATION_PLAN.md .

chmod +x loop.sh
mkdir -p specs
```

이러면 프로젝트 루트에 이런 구조가 생긴다:

```
my-project/
├── loop.sh                  # 메인 루프 스크립트
├── PROMPT_plan.md           # "계획만 세워" 프롬프트
├── PROMPT_build.md          # "구현해" 프롬프트
├── AGENTS.md                # 빌드/테스트 명령어 메모
├── IMPLEMENTATION_PLAN.md   # AI가 관리하는 할 일 목록
├── specs/                   # 내가 쓰는 요구사항 명세
└── src/                     # 소스코드
```

<br/>

## 각 파일의 역할

여기서 이해해야 할 핵심이 있다. **사람이 쓰는 파일**과 **AI가 관리하는 파일**이 나뉜다.

### 사람이 쓰는 파일

**`specs/*.md`** — 요구사항 명세다. 주제별로 파일을 나눠서 "이런 거 만들어줘"를 적는다.

```markdown
<!-- specs/authentication.md -->

# 인증 시스템

## 요구사항

- 이메일/비밀번호로 회원가입
- JWT 기반 로그인
- 비밀번호 재설정 기능
```

**`AGENTS.md`** — 프로젝트를 어떻게 빌드하고 테스트하는지 AI한테 알려주는 파일이다.

```markdown
## Build & Run

- 설치: `npm install`
- 실행: `npm run dev`

## Validation

- Tests: `npm test`
- Typecheck: `npx tsc --noEmit`
- Lint: `npm run lint`
```

이 파일이 없으면 AI가 테스트를 어떻게 돌려야 하는지 모른다. **반드시 먼저 채워야 한다.**

### AI가 관리하는 파일

**`IMPLEMENTATION_PLAN.md`** — AI가 매 반복마다 업데이트하는 할 일 목록이다. 이게 Ralph Loop의 **기억 장치** 역할을 한다. 새 세션이 시작되면 이 파일을 읽고 "아, 여기까지 했구나. 다음은 이거 해야지"를 판단한다.

<br/>

## 실행: 2단계 워크플로우

### Step 1. 계획 모드

먼저 AI한테 "뭘 해야 하는지 파악만 해"라고 시킨다.

```bash
./loop.sh plan 5    # 계획 모드, 최대 5회 반복
```

이러면 AI가 `specs/` 폴더의 명세를 읽고, 기존 소스코드를 분석해서, `IMPLEMENTATION_PLAN.md`에 우선순위별 작업 목록을 생성한다.

**중요한 건 이 단계에서는 코드를 한 줄도 안 건드린다는 것.** 순수하게 분석과 계획만 한다.

계획이 나오면 직접 열어보고 검토한다. 말도 안 되는 계획이면 수정하거나 다시 돌리면 된다. 계획 생성 비용은 크지 않으니까 부담 없다.

### Step 2. 빌드 모드

계획이 괜찮으면 구현을 시작한다.

```bash
./loop.sh 20    # 빌드 모드, 최대 20회 반복
```

이제 AI가 매 반복마다:

1. `IMPLEMENTATION_PLAN.md`에서 가장 중요한 항목을 고른다
2. 기존 코드를 확인한다 (이미 구현된 건 건너뜀)
3. 구현한다
4. 테스트를 돌린다
5. 통과하면 커밋 & 푸시
6. `IMPLEMENTATION_PLAN.md`를 업데이트한다
7. 다음 반복으로...

20번 반복이면 20개의 작업이 처리되는 셈이다. 물론 하나의 작업이 복잡하면 한 반복에서 끝나지 않을 수도 있지만, 그래도 사람이 일일이 시키는 것보다는 훨씬 빠르다.

<br/>

## 프롬프트 설계의 묘미

`PROMPT_build.md`를 열어보면, 단순히 "구현해"가 아니라 꽤 정교한 지시가 들어있다.

몇 가지 핵심적인 표현들:

- **"don't assume not implemented"** — 가장 중요한 지시다. AI가 "이거 아직 안 만들어졌겠지"하고 처음부터 새로 짜버리는 걸 방지한다. 먼저 코드베이스를 검색해서 이미 있는지 확인하라는 의미.
- **"study"** (`read` 대신) — 단순히 읽는 게 아니라 맥락을 이해하라는 뉘앙스.
- **"using parallel subagents"** — Sonnet 서브에이전트를 수백 개까지 병렬로 돌려서 코드베이스를 빠르게 분석한다.
- **"only 1 subagent for build/tests"** — 빌드와 테스트는 1개의 서브에이전트로만. 여러 개가 동시에 빌드하면 충돌이 나니까.
- **"Ultrathink"** — Claude한테 깊이 생각하라는 시그널.

이 프롬프트 하나하나가 반복적인 실패 → 관찰 → 수정을 거쳐 다듬어진 거다. Ralph Loop의 진짜 경쟁력은 루프 스크립트가 아니라 **이 프롬프트 엔지니어링**에 있다.

<br/>

## 실제로 돌려보면서 느낀 것들

### 좋았던 점

**사람이 빠지니까 오히려 일관성이 올라간다.** 사람이 중간에 개입하면 "아 이건 이렇게 해야지"하고 방향을 틀 때가 있다. Ralph Loop에서는 `specs/`에 쓴 대로만 간다. 좋게 말하면 일관적이고, 나쁘게 말하면 융통성이 없다.

**새벽에 돌려놓고 아침에 확인하는 패턴이 가능하다.** `./loop.sh 30` 걸어놓고 자면, 아침에 커밋 히스토리를 보면서 "오, 여기까지 했네"라고 확인할 수 있다. 이건 솔직히 꽤 신기한 경험이다.

**git 히스토리가 깔끔하다.** 매 작업마다 커밋이 찍히니까, 뭘 했는지 추적이 쉽다. 문제가 생기면 해당 커밋만 revert하면 된다.

### 주의할 점

**비용.** 이건 진짜 중요하다. Opus 모델로 루프를 돌리면 반복당 API 비용이 만만치 않다. `max_iterations`를 설정 안 하고 무제한으로 돌리면 아침에 일어나서 청구서를 보고 놀랄 수 있다. **반드시 반복 횟수를 제한하자.**

**`--dangerously-skip-permissions` 옵션.** 이름부터 위험하다. AI가 파일 삭제, 패키지 설치 등 모든 권한을 자동 승인받는다. 프로덕션 환경에서 돌리면 안 되고, Docker 같은 격리된 환경에서 돌리는 게 좋다.

**계획 없이 빌드 모드부터 돌리면 안 된다.** AI가 방향을 잡지 못하고 이상한 곳으로 질주한다. 반드시 plan → 검토 → build 순서를 지키자.

**AI가 가끔 삽질한다.** 같은 문제를 여러 반복에 걸쳐 반복하거나, 이미 구현된 걸 새로 짜버리는 경우가 있다. `IMPLEMENTATION_PLAN.md`와 `AGENTS.md`를 중간중간 확인해서 궤도를 잡아줘야 한다. 완전 방치는 아직 위험하다.

<br/>

## 어떤 프로젝트에 적합할까?

**잘 맞는 경우:**

- 초기 보일러플레이트가 많은 프로젝트 (CRUD API, 관리자 대시보드 등)
- 명세가 명확하고 구체적인 경우
- 테스트 인프라가 이미 갖춰진 프로젝트
- 반복적인 구현 작업이 많은 경우

**안 맞는 경우:**

- 요구사항이 모호하거나 자주 바뀌는 경우
- 디자인 감각이나 UX 판단이 필요한 작업
- 레거시 코드 리팩토링 (AI가 기존 맥락을 오해하기 쉽다)
- 보안에 민감한 코드

<br/>

## 정리

Ralph Loop은 결국 **"AI의 컨텍스트 한계를 파일 시스템으로 우회한다"**는 아이디어다.

대화는 잊어도, 파일은 남는다. git 히스토리도 남는다. 그래서 무한 루프가 가능하다.

하지만 만능은 아니다. 프롬프트를 잘 짜야 하고, 명세를 잘 써야 하고, 중간중간 확인도 해야 한다. "AI한테 전부 맡기고 나는 놀겠다"는 아직 환상이다.

그래도 방향은 분명하다. 개발자의 역할이 "코드를 짜는 사람"에서 **"AI가 잘 짜도록 명세를 쓰고 품질을 검증하는 사람"**으로 넘어가고 있다는 것.

Ralph Loop은 그 변화의 현재 진행형이다.

---

### 참고

- [ralph-playbook GitHub](https://github.com/ClaytonFarr/ralph-playbook) — 이 글에서 사용한 구현체
- [Ralph 기법 완벽 정리 - TILNOTE](https://tilnote.io/en/pages/69632d981569d9997d65c18e)
- [Claude Code Ralph Wiggum 사용법 - TILNOTE](https://tilnote.io/en/pages/695f083960c8a0df1c72b01e)
