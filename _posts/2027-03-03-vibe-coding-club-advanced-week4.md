---
layout: post
title: "Sandbox와 동적 코드 실행"
date: 2026-03-02 22:00:00 +0900
categories: [400-area]
tags:
  [
    ai,
    sandbox,
    security,
    dynamic-code-execution,
    gvisor,
    firecracker,
    vibe-coding,
  ]
description: "바이브 코딩 클럽 Advanced 4주차 정리. Sandbox 필요성, 격리 기술 스택, 실제 구현체 비교, 실습 3개를 기록했다."
---

<img src="https://github.com/user-attachments/assets/a63a5562-4143-4ac5-80ec-39fab8887315" />

_[vibe-coding-club.vercel.app](https://club-house-sigma.vercel.app/)_

---

Advanced 4주차는
"AI가 만든 코드를 어디서 실행할 것인가"를 다뤘다.

이번 주는 기능보다 경계를 먼저 본 시간이었다.
코드 품질만큼 실행 환경이 중요하다는 걸 다시 확인했다.

---

## 이번 주 구조

Week4 구성은 4개였다.

1. 왜 Sandbox인가
2. 격리 기술 스택
3. 실제 구현체 비교
4. 실습

실습은 3개로 진행됐다.

- Sandbox Escape Demo
- Safe Code Executor
- Network Isolation Demo

---

## 왜 샌드박스인가

AI 코드 실행에서 가장 불편한 지점은 예측 가능성이 낮다는 점이다.
같은 요청에도 코드가 달라진다.
실행 전에는 부작용 범위를 확신하기 어렵다.

이번 주에서 반복된 위험은 세 가지였다.

- Sandbox Escape
- Data Exfiltration
- Resource Exhaustion

예시는 단순했다.
CSV처럼 평범한 입력에 악성 문자열이 섞이면,
실행 코드가 외부 유출로 이어질 수 있다.

그래서 핵심은 "완벽한 코드"보다
"실수해도 밖으로 번지지 않는 경계"였다.

---

## 방어 원칙

기본 원칙은 Defense in Depth였다.
한 겹으로 막지 않는다.
여러 겹으로 줄인다.

흐름은 보통 이렇게 잡는다.

- 정적 분석
- 격리 실행
- 리소스 제한
- 시스템콜 제한
- 네트워크 격리
- 감사 로그

여기서 특히 계속 강조된 건 Allowlist였다.

- Denylist: 기본 허용, 일부 차단
- Allowlist: 기본 차단, 필요한 것만 허용

실행 환경은 결국 후자가 안전했다.

---

## 격리 기술 스택

이번 주 설명을 한 줄로 줄이면 이거였다.

- 무엇을 보게 할지
- 얼마나 쓰게 할지
- 무엇을 하게 할지

각각 대응되는 기술은 다음이었다.

- Linux Namespaces
- cgroups
- seccomp

이 3가지를 바닥으로 깔고,
위에서 Docker, gVisor, Firecracker 같은 선택지가 올라간다.

gVisor는 커널 접근 경계를 더 두껍게 만든 선택지였고,
Firecracker는 격리 강도를 높이면서 부팅 시간을 줄인 MicroVM 쪽 선택지였다.

---

## 실제 구현체

이번 주에서 비교한 구현체는 다음이었다.

- E2B
- Modal
- OpenAI Code Interpreter
- Claude Code

같은 "코드 실행" 문제를 풀어도
각 서비스가 택한 제약은 달랐다.

- 네트워크를 어디까지 열지
- 파일시스템을 얼마나 남길지
- cold start와 격리 강도 중 무엇을 우선할지

Claude Code 파트는
프록시 경유 제어 관점에서 정리되어 있었다.
임의 외부 서버로 바로 나가는 경로를 줄이고,
허용된 경로 중심으로 운영하는 방식이다.

---

## 실습

실습은 개념을 코드로 확인하는 흐름이었다.

### 실습 1

`01_sandbox_escape_demo.py`

AST 기반 정적 분석으로
`import os`, `__import__`, `__subclasses__` 같은 패턴을 차단한다.

### 실습 2

`02_safe_code_executor.py`

`subprocess`와 `resource`로
CPU, 메모리, 파일 크기, 프로세스 수를 제한한다.
타임아웃도 별도로 둔다.

### 실습 3

`03_network_isolation_demo.py`

네트워크 접근을 모드별로 제어한다.
화이트리스트와 DLP 패턴 탐지를 같이 확인한다.

실습 코드는 아래 저장소에서 확인할 수 있다.

- [vibe-ai-coding-club/ai-study-2026](https://github.com/vibe-ai-coding-club/ai-study-2026)

---

## 4주차를 마치며

이번 주는 보안 기능을 많이 배운 주차라기보다,
실행 경계 설계를 먼저 배우는 주차에 가까웠다.

생성 모델이 좋아질수록
실행 안전성은 자동으로 해결되지 않는다.
오히려 더 먼저 설계해야 했다.

코드 실행을 붙일 때는 이제
모델 선택보다 격리 전략부터 확인하게 될 것 같다.

---

### 메모

- AI 코드 실행은 기능 이전에 경계 설계 문제다
- 기본 차단 후 허용하는 방식이 운영 리스크를 줄인다
- Namespaces, cgroups, seccomp는 설명용 개념이 아니라 실무 기본기다
- 실습으로 보면 이론보다 훨씬 빨리 이해된다
