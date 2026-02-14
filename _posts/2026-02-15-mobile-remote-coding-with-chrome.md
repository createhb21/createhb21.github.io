---
layout: post
title: "핸드폰으로 Claude Code 작업 확인하고 진행하는 법"
date: 2026-02-14 12:00:00 +0900
categories: [200-pick-up]
tags: [ai, claude-code, remote-desktop, chrome, mobile, productivity]
description: "Chrome 원격 데스크톱을 활용하면 핸드폰에서도 Claude Code 등 AI CLI 도구의 작업을 확인하고 진행할 수 있다."
---

Claude Code 등 AI CLI 도구로 작업하다 보면, 항상 컴퓨터 앞에 앉아 있어야 한다는 제약이 있다. 터미널에서 돌아가는 도구 특성상, 진행 상황을 확인하거나 승인이 필요한 작업을 처리하려면 데스크톱이 필수였다.

그런데 이걸 핸드폰에서도 할 수 있는 방법을 발견했다.

![핸드폰에서 Chrome 원격 데스크톱으로 Claude Code 작업 확인](/assets/images/etc/remote-coding-mobile/mobile-remote-desktop.jpg)

---

## Chrome 원격 데스크톱 활용

답은 의외로 간단했다. **크롬의 원격 데스크톱 기능**을 활용하면 된다.

Chrome Remote Desktop은 구글이 제공하는 무료 원격 접속 도구로, 브라우저나 모바일 앱을 통해 다른 컴퓨터에 접속할 수 있다. 이걸 활용하면 핸드폰에서 내 데스크톱의 터미널을 그대로 볼 수 있고, Claude Code의 작업 진행 상황을 실시간으로 확인하면서 필요한 입력도 할 수 있다.

### 설정 방법

1. 데스크톱 크롬에서 [Chrome Remote Desktop](https://remotedesktop.google.com) 접속
2. 원격 액세스 설정에서 내 컴퓨터 등록
3. 핸드폰에 Chrome Remote Desktop 앱 설치
4. 같은 구글 계정으로 로그인 후 접속

---

## 이제 어디서든 코딩이 가능하다

이게 되면서 작업 환경의 제약이 사라졌다.

- **누워서도** 코딩 가능
- **산에 올라가서도** 코딩 가능
- **카페에서 노트북 없이도** Claude Code 작업 확인 가능

Ralph Loop처럼 자율 코딩 루프를 돌려놓고 외출한 뒤, 핸드폰으로 진행 상황을 체크하면서 필요할 때만 개입하는 워크플로우가 가능해진 것이다.

AI CLI 도구의 가장 큰 단점이었던 "데스크톱 종속성"이 이 한 가지 트릭으로 해결된다.
