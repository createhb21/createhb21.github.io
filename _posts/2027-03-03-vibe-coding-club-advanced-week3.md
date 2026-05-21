---
layout: post
title: "에이전틱 워크플로우와 SDLC"
date: 2027-02-16 22:00:00 +0900
categories: [400-area]
tags: [ai, agent, workflow, sdlc, langgraph, claude-code, vibe-coding]
description: "바이브 코딩 클럽 Advanced 3주차 정리. Agentic Workflow, Agent 아키텍처, SDLC와 AI, 실습 4종을 한 번에 정리했다."
---

<img src="https://github.com/user-attachments/assets/a63a5562-4143-4ac5-80ec-39fab8887315" />

_[vibe-coding-club.vercel.app](https://club-house-sigma.vercel.app/)_

---

Advanced 3주차는 "에이전트를 어떻게 쓰느냐"에서 한 걸음 더 들어가,
"에이전트를 어떻게 일하게 설계하느냐"를 다룬 주차였다.

이번 주를 관통한 키워드는 네 가지였다.

1. Agentic Workflow & Design Patterns
2. Agent 아키텍처 심화
3. SDLC와 AI
4. 실습 4종

- ReAct Agent
- Reflection Agent
- LangGraph Multi-Agent Pipeline
- Claude Code로 Agentic SDLC 체험

---

## Agentic Workflow

개별 프롬프트를 잘 쓰는 것과,
워크플로우 전체를 잘 설계하는 건 다른 문제였다.

이번 주에는 특히 이 차이가 크게 느껴졌다.

- 단일 요청에 잘 답하는 모델
- 목표를 쪼개고 순서대로 처리하는 에이전트

둘 다 비슷해 보이지만,
실제 업무에서는 두 번째가 훨씬 안정적으로 남는다.

내가 이해한 핵심은 "패턴"이었다.

- ReAct처럼 생각-행동-관찰을 반복하는 패턴
- Reflection처럼 한 번 더 검토해 오답을 줄이는 패턴
- 여러 역할을 분리해서 협업시키는 멀티 에이전트 패턴

결국 에이전트 품질은 모델 성능만으로 결정되지 않았다.
워크플로우를 어떻게 짜느냐가 절반 이상이었다.

---

## Agent 아키텍처

아키텍처 파트에서는 "역할 분리"를 계속 강조했다.

한 에이전트가 전부 하게 두면 빠르게 복잡해지고,
오류 원인 추적도 어려워진다.

그래서 보통 이런 식으로 나눈다.

- 계획을 세우는 역할
- 실행하는 역할
- 검토하는 역할

이렇게 나누면 좋은 점이 분명했다.

- 어느 단계에서 실패했는지 찾기 쉽다
- 교체 범위가 작아져 유지보수가 쉬워진다
- 로그 해석이 쉬워져 운영이 편해진다

"똑똑한 에이전트 한 명"보다,
"역할이 분리된 시스템"이 길게 보면 더 낫다는 걸 다시 확인했다.

---

## SDLC와 AI

이번 주차에서 개인적으로 가장 인상 깊었던 파트였다.

SDLC를 AI에 억지로 붙이는 게 아니라,
각 단계에서 AI가 어디까지 들어오면 좋은지 선을 그어보는 접근이었다.

흐름은 크게 3단계로 정리됐다.

1. 전통적 SDLC
2. AI-Assisted SDLC
3. Agentic SDLC

전통적 SDLC가 사람이 단계를 직접 넘기는 방식이었다면,
AI-Assisted SDLC는 단계마다 보조를 붙이는 형태에 가깝다.

- 요구사항 정리 보조
- 설계 초안 생성 보조
- 구현/테스트 자동화 보조
- 배포/운영 로그 요약 보조

Agentic SDLC는 여기서 한 단계 더 간다.
도구가 "도와주는 수준"을 넘어,
에이전트가 스스로 다음 액션을 이어가는 구조를 만든다.

그리고 이 지점에서 아키텍처 패턴이 갈린다.

### Human in the Loop

사람 승인 지점을 명확히 남겨두는 방식.

속도는 다소 느릴 수 있지만,
품질 통제와 책임 경계가 분명하다.

### Agent in the Loop

기본 흐름은 자동으로 돌리고,
특정 조건에서만 사람이 개입하는 방식.

운영 효율과 안정성의 균형을 잡기 좋다.

### Fully Autonomous

목표부터 실행까지 자동화 비중이 가장 높은 방식.

효율은 크지만,
검증과 안전장치가 준비되지 않으면 위험도 같이 커진다.

이번 주 내용을 보면서,
실무에서는 결국 Human-in-the-Loop와 Agent-in-the-Loop 사이에서
팀 상황에 맞는 지점을 찾게 된다는 생각이 들었다.

---

## 실습

실습 가이드는 아래 네 가지였다.

1. ReAct Agent (Tool Use + Planning)
2. Reflection Agent (자기 성찰 패턴)
3. LangGraph Multi-Agent Pipeline
4. Claude Code로 Agentic SDLC 체험

실습 코드는 아래 저장소를 따라가면 된다.

- [vibe-ai-coding-club/ai-study-2026](https://github.com/vibe-ai-coding-club/ai-study-2026)

나는 이번 주 실습을 하면서,
"모델이 얼마나 똑똑한가"보다
"실패했을 때 복구 가능한 구조인가"를 더 보게 됐다.

그 관점으로 보니,
LangGraph나 Claude Code 같은 도구를 볼 때도
기능 목록보다 워크플로우 복원력부터 체크하게 됐다.

---

## 3주차를 마치며

Advanced 3주차는 개념이 많아서 처음엔 산만하게 느껴졌다.
그런데 끝나고 나니 하나로 모였다.

"에이전트를 만드는 일"은
프롬프트를 예쁘게 쓰는 일이 아니라,
일하는 구조를 설계하는 일이라는 것.

그리고 SDLC에 AI를 붙일 때도
정답 패턴이 하나 있는 게 아니라,
조직의 리스크 허용 범위와 운영 역량에 따라 답이 달라진다는 점이 명확했다.

다음 주차에서는 이 구조를 실제 프로젝트 기준으로
더 좁혀서 적용해보게 될 것 같다.

---

### 메모

- 워크플로우 설계가 에이전트 품질을 크게 좌우한다
- 역할 분리 없는 에이전트는 운영 단계에서 빠르게 무너진다
- AI-Assisted와 Agentic은 자동화 수준뿐 아니라 책임 구조가 다르다
- 실무에서는 Human-in-the-Loop와 Agent-in-the-Loop 사이에서 균형점을 찾게 된다
