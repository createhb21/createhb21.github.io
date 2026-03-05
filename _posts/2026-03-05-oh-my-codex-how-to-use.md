---
layout: post
title: "oh-my-codex 전체 운영 가이드: 설치부터 팀 파이프라인까지"
date: 2026-03-05 18:40:00 +0900
categories: [400-area]
tags: [oh-my-codex, codex-cli, team, ralph, workflow]
description: "oh-my-codex를 처음 붙일 때 필요한 설치, 명령 체계, 모드 선택, 상태 관리, 팀 파이프라인, 트러블슈팅까지 한 번에 정리한 실전 운영 가이드."
---

oh-my-codex(OMX)는 Codex CLI를 "한 명짜리 도구"에서 "여러 에이전트를 굴리는 작업 시스템"으로 바꿔주는 레이어다.  
기능이 많아서 처음엔 헷갈리기 쉽다. 이 글은 기능 이름보다 **언제 무엇을 고르면 되는지** 중심으로 정리했다.

- 공식 문서: https://yeachan-heo.github.io/oh-my-codex-website/docs.html

## 1) 큰 그림: OMX를 언제 켜야 하는가

작업이 커질수록 병목은 코딩이 아니라 조율에서 생긴다.  
범위 정리, 병렬 실행, 마감 검증을 섞어서 처리하면 재작업이 늘어난다.

OMX는 이 과정을 모드로 나눈다.

- 범위 정리: `plan`, `ralplan`
- 병렬 실행: `team`, `ultrawork`
- 마감 검증: `ralph`
- 단건 자동화: `autopilot`
- 운영 보조: `trace`, `note`, `cancel`, `ecomode`

## 2) 설치와 시작 점검: setup → doctor → help

처음 도입할 때는 아래 순서를 고정해두면 실수가 줄어든다.

```bash
omx setup
omx doctor
omx help
```

- `setup`: 필요한 구성요소 설치/등록
- `doctor`: 실행 환경 점검
- `help`: 사용 가능한 명령 확인

## 3) 입력 방식부터 구분하기: `$skill` vs `omx ...`

`$ralplan`, `$team`은 **Codex 대화 입력창**에서 쓰는 스킬 호출이고,  
`omx team ...`은 **터미널**에서 실행하는 CLI 명령이다.

```text
# Codex 대화창
$ralplan "결제 모듈 리팩터 계획"
$team 5:executor "execute approved plan"
$ralph "final verification"
$note "scope: payment + webhook"
$trace
$cancel
```

```bash
# 터미널
omx plan --consensus "결제 모듈 리팩터 계획"
omx team 5:executor "execute approved plan"
omx ralph "final verification"
omx doctor
omx help
```

의도는 같아도 입력 채널이 다르다는 점만 기억하면 된다.

## 4) 모드 선택 기준: 한 줄 요약표

- `plan`: 범위가 모호할 때 분해부터
- `ralplan`: 합의형 계획(Planner-Architect-Critic)
- `team`: 큰 작업을 병렬 워커로 실행
- `ralph`: 끝단 검증 루프
- `autopilot`: 단순 목표를 빠르게 처리
- `ultrawork`: 독립 이슈 다건 병렬
- `ecomode`: 비용/토큰 절약 모드
- `cancel`: 활성 모드 종료

## 5) 모델 라우팅과 delegation: 왜 역할을 나누는가

핵심은 역할 분리다.

- Low complexity: `explore`, `writer`
- Standard: `executor`, `debugger`, `test-engineer`
- High complexity: `architect`, `critic`

실전에서는 보통 `explore -> executor -> test-engineer -> architect/critic` 순으로 배치한다.

## 6) 상태 지속성과 MCP 도구: 중간에 멈춰도 이어가기

OMX는 `.omx/`에 상태를 남긴다.

- `.omx/state/`: 모드 상태(JSON)
- `.omx/notepad.md`: 세션 메모
- `.omx/plans/`: PRD/Test Spec
- `.omx/project-memory.json`: 프로젝트 지식
- `.omx/logs/`: 실행 로그

중간에 세션이 끊겨도 이어가기 쉬운 이유가 여기 있다.
코드 진단/탐색에는 MCP 도구를 같이 쓰면 좋다.

- `lsp_diagnostics`, `lsp_diagnostics_directory`
- `ast_grep_search`, `ast_grep_replace`
- `trace_summary`, `trace_timeline`

## 7) Team 파이프라인은 이렇게 읽으면 쉽다

문서의 canonical 흐름은 아래다.

`team-plan -> team-prd -> team-exec -> team-verify -> team-fix`

운영 관점에서 보면:

- `team-plan`: 분해/우선순위
- `team-prd`: acceptance criteria 고정
- `team-exec`: 병렬 실행
- `team-verify`: 증거 기반 검증
- `team-fix`: 실패 항목 보정 후 재진입

`team-fix`는 무한 반복이 아니라 상한을 둔다.  
팀 설정마다 다르지만, 실무에서는 예시로 **3회 cap**을 많이 쓴다. 3회를 넘기면 `failed`로 종료한다.

종료 상태는 `complete`, `failed`, `cancelled`로 구분한다.  
중단할 때는 `cancel`로 `cancelled`를 남기고 종료한다.

## 8) 실전 패턴 4가지

`ralplan -> team -> ralph`는 대표 패턴이지만 정답은 하나가 아니다.

1. 요구가 크고 모호함: `ralplan -> team -> ralph`  
2. 범위가 작고 단순함: `autopilot` 또는 `autopilot -> ralph`  
3. 독립 이슈 다건: `ultrawork` 중심 + 필요 시 `team`  
4. 범위가 명확한 수정: `team` 또는 `ralph` 바로 진입

막히면 순서대로 확인하면 된다.

- `doctor`: 환경 확인
- `trace`: 멈춘 지점 확인
- `note`: 결정 근거 기록
- `cancel`: 상태 정리 후 재시작
- `ecomode`: 비용 절약이 우선일 때 적용

```bash
omx setup
omx doctor
omx plan --consensus "작업 목표 + 완료 조건"
omx team 5:executor "execute approved plan"
omx ralph "final verification"
omx cancel
```

결국 핵심은 같다. 범위를 먼저 고정하고, 실행을 분리하고, 검증으로 닫는다.
