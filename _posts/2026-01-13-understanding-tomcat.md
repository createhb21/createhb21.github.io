---
layout: post
title: "Understanding Tomcat"
date: 2026-01-13 15:00:00 +0900
categories: [300-project]
tags: [react, jsp, legacy, tomcat]
---

_Legacy JSP 코드를 이해하는 데 도움이 되는 글이 되기를_

---

> _Tomcat(톰캣) = "Java 버전의 Node.js 서버"_

---

#### 1. 비유로 이해하기

평소 리액트를 개발할 때 로컬에서 개발하려면 터미널에 `npm run start` (또는 `yarn start`) 입력하면,
**Node.js**가 돌아가면서 내 컴퓨터에 웹 서버를 띄워주고, 브라우저가 접속할 수 있게 해준다.

- **Node.js**: 자바스크립트 파일을 실행시켜 주는 애
- **Tomcat**: **JSP(Java) 파일을 실행시켜 주는 애**

JSP 파일은 그 자체로는 그냥 텍스트 파일일 뿐이다.
이걸 브라우저가 이해할 수 있는 HTML로 변환해서 던져주는 "엔진(서버 프로그램)"이 필요한데,
그게 바로 Tomcat 이다.

#### 2. 동작 방식의 차이

본질을 이해하기 위해 이 차이를 아는 게 좋다.

- **React**
  - 브라우저가 텅 빈 HTML과 JS 파일을 다운로드 받는다.
  - 브라우저 안에서 JS가 돌면서 화면을 그란다. (**Client Side Rendering**)
  - 서버는 그냥 파일만 던져주면 끝이다.
- **JSP + Tomcat (옛날 방식)**
  - 브라우저가 "메인 페이지 줘!"라고 요청하면,
  - **Tomcat**이 서버 컴퓨터 안에서 JSP 파일(Java 코드 + HTML 섞인 것)을 읽어서 **HTML을 완성**시킨다. (**Server Side Rendering**)
  - 완성된 HTML을 브라우저한테 툭 던져준다.

#### 3. React 내부 iframe 구조를 예시로 들어서 생각해보기

React 프로젝트 내부에 JSP 페이지를 불러오는 상황을 iframe 구조로 비유하면 다음과 같은 흐름으로 동작한다.

1. 사용자 브라우저에는 **React 앱**이 떠있다.
2. 그 안의 네모난 박스(`iframe`)가 하나 있다.
3. 그 박스는 **"야, Tomcat아! JSP 페이지 좀 HTML로 만들어서 보내줘!"** 라고 요청한다.
4. 뒤에 숨어있는 **Tomcat**이 코드를 막 돌려서 HTML을 만들고, 그걸 `iframe` 안에 쏴준다.

---

#### 요약

1. **Tomcat**은 **Java/JSP** 코드를 돌려서 웹페이지로 보여주는 **서버 프로그램**이다.
2. 리액트의 `npm start` (Node.js 서버)와 비슷한 역할을 한다고 보면 된다.
