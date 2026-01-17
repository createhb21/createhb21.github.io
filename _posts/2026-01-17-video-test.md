---
layout: post
title: "Video Log Test"
date: 2026-01-17 16:00:00 +0900
categories: [100-private-log]
video: /assets/videos/bodycodi-playground.mp4
tags: [video, test, playground]
---

<video width="100%" controls poster="{{ '/assets/postImages/TestThumbnail/playground-thumbnail.jpg' | relative_url }}" playsinline preload="metadata">
  <source src="{{ '/assets/videos/bodycodi-playground.mp4' | relative_url }}" type="video/mp4">
  Your browser does not support the video tag.
</video>

_assets/videos 폴더에 있는 로컬 동영상을 테스트합니다._

목록에서는 썸네일 대신 자동 재생(muted)되는 비디오가 보여야 하고,
상세 페이지에서는 위와 같이 컨트롤이 가능한 비디오가 보여야 합니다.
