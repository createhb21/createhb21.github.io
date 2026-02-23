---
layout: post
title: "MFE/모노레포 질문에서 진짜 검증되는 것"
date: 2026-02-16 22:00:00 +0900
categories: [400-area]
tags: [mfe, monorepo, nx, turborepo, auth, deployment]
description: "MFE 입자 크기, 인증 동기화, 브랜치 전략, affected build, 공통 라이브러리 설계를 운영 관점으로 설명했다."
---

MFE/모노레포 주제는 아키텍처 이론보다 조직 운영 문제에 가깝다.

면접에서 이 질문을 받으면 나는 먼저 "어디서 병목이 생겼는지"부터 말한다.

---

### Fragment vs Application

Fragment는 팀 독립 배포에 좋지만 통합 비용이 크다.
Application은 통합이 쉽지만 재사용/공유가 약해질 수 있다.

결국 선택 기준은 기술이 아니라 조직 경계다.

- 팀 경계가 페이지 단위면 Application
- 한 화면 안에 다팀 협업이 많으면 Fragment

### MFE 인증

토큰 공유 자체보다 중요한 건 상태 전이 동기화다.

로그인/만료/갱신 이벤트를 shell 기준으로 통일하지 않으면
앱마다 인증 상태가 갈라진다.

### 모노레포 affected build

Nx/Turbo에서 진짜 이득은 캐시가 아니라 영향 범위 축소다.

변경된 패키지와 의존 노드만 테스트/빌드하면,
CI 시간과 배포 반경을 동시에 줄일 수 있다.

### 공통 라이브러리

내 철학은 한 줄이다.

> 코어는 작고 단단하게, 확장은 바깥에서 유연하게.

공통 라이브러리를 편의 기능 모음으로 만들면,
몇 달 뒤엔 전체 배포 병목이 된다.

### 실제 적용에서 자주 실패하는 지점

MFE/모노레포 논의에서 기술 선택보다 먼저 정리해야 할 건 팀 간 계약이다. Module Federation을 도입하면 런타임 결합을 느슨하게 만들 수 있지만([Module Federation Concept](https://webpack.js.org/concepts/module-federation), [Plugin](https://webpack.js.org/plugins/module-federation-plugin/)), 계약이 느슨하면 배포는 독립적이어도 장애는 동시다발로 터진다.

그래서 우리는 세 가지 계약을 먼저 고정했다.

- UI 계약: Shell과 Remote 간 렌더링 책임
- 인증 계약: 로그인/만료/갱신 이벤트 전파
- 배포 계약: 브레이킹 변경 공지와 롤백 책임

모노레포 빌드는 affected 전략이 핵심이었다. Nx에서는 PR 영향 범위만 실행해 CI를 줄이고([Nx affected](https://nx.dev/ci/features/affected)), Turborepo는 캐시를 적극 활용해 반복 작업을 줄였다([Turborepo Caching](https://turbo.build/repo/docs/crafting-your-repository/caching)). 이 두 가지를 함께 쓰면 "모노레포는 느리다"는 인식이 많이 줄어든다.

또한 마이크로 프론트엔드를 도입했는데 팀 경계가 정리되지 않으면 오히려 복잡성이 증가한다. 이때 Team Topologies 관점이 유용했다. 기술 경계를 조직 경계와 맞추지 않으면, 결국 통합 비용이 사람에게 전가된다([Team Topologies](https://teamtopologies.com/)).

마지막으로 버전 정책을 엄격히 했다. shared 라이브러리에는 semver를 강제해 위험 변경을 명시하고([SemVer](https://semver.org/)), 브라우저 지원 범위는 browserslist 기준으로 합의해 런타임 불일치를 줄였다([Browserslist](https://github.com/browserslist/browserslist)). MFE와 모노레포는 도구 문제가 아니라, 계약과 운영의 문제라는 결론에 도달했다.

## 참고자료
- [Webpack - Module Federation](https://webpack.js.org/concepts/module-federation)
- [Webpack - ModuleFederationPlugin](https://webpack.js.org/plugins/module-federation-plugin/)
- [Nx - Affected](https://nx.dev/ci/features/affected)
- [Turborepo - Caching](https://turbo.build/repo/docs/crafting-your-repository/caching)
- [Team Topologies](https://teamtopologies.com/)
- [Martin Fowler - Micro Frontends](https://martinfowler.com/articles/micro-frontends.html)
- [SemVer](https://semver.org/)
- [Browserslist](https://github.com/browserslist/browserslist)

### 조직 관점에서 다시 정리한 선택 기준

MFE와 모노레포를 검토할 때 제가 자주 했던 실수는, 기술 장단점을 먼저 비교하고 조직 상황을 나중에 본 것이다. 현실에서는 순서가 반대여야 했다. 팀 구조와 책임 경계가 먼저 정리되지 않으면, 어떤 도구를 써도 운영 복잡도는 줄지 않았다.

예를 들어 MFE를 도입하면 팀 자율성이 올라갈 거라고 기대하기 쉽다. 실제로는 공통 인증, 공통 디자인, 공통 배포 규칙이 약하면 자율성보다 충돌이 더 늘어난다. 그래서 지금은 MFE를 기술 선택이 아니라 조직 계약으로 본다. 어떤 팀이 어떤 SLA를 지고, 어떤 변경을 언제 공지하고, 장애 발생 시 어느 팀이 1차 대응하는지까지 먼저 합의해야 한다.

모노레포도 비슷하다. 하나의 저장소로 모으면 협업이 쉬워질 거라는 기대가 있지만, 소유권 경계가 불명확하면 리뷰 대기열만 늘어난다. 그래서 저는 저장소 구조와 함께 코드 오너십 규칙, 영향 범위 표시, 릴리즈 책임을 같이 설계한다. 이 과정이 번거롭지만, 장기적으로는 갈등 비용을 크게 줄였다.

개인적으로는 "작게 시작해서 점진 확장"이 가장 안전한 접근이었다. 처음부터 모든 도메인을 MFE로 분해하지 않고, 경계가 명확한 영역부터 실험해 운영 데이터로 검증했다. 이 방식은 기술적으로 화려하진 않지만 실패 비용이 작다는 장점이 있다.

## MFE/모노레포 도입 전 점검 질문 10개

1. 팀별 소유 도메인이 실제로 분리돼 있는가?
2. 인증/권한 상태를 공통으로 다룰 수 있는가?
3. 공통 UI 정책과 예외 정책이 문서화돼 있는가?
4. 배포 실패 시 롤백 책임이 명확한가?
5. 영향 범위를 자동으로 계산하는 체계가 있는가?
6. 공통 라이브러리의 버전 정책이 있는가?
7. 브레이킹 변경 공지 채널이 고정돼 있는가?
8. 모니터링 지표를 팀별/도메인별로 분리할 수 있는가?
9. 신규 팀원이 경계를 이해할 문서가 있는가?
10. 3개월 뒤에도 유지 가능한 운영 인력이 있는가?

이 질문에 절반 이상 확신이 없다면, 저는 도입 속도를 늦추는 편이 낫다고 생각한다. 기술은 언제든 적용할 수 있지만, 신뢰를 잃은 운영은 회복이 오래 걸리기 때문이다.
