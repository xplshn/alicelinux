+++
date = '2025-01-10T04:34:30'
draft = false
title = 'repos'
[params.author]
  name = 'emmett1'
  email = 'emmett1.2miligrams@protonmail.com'
+++
PACKAGE REPOSITORY
==================

Theres 4 repos available in Alice:

- core: contains base packages for Alice (required)
- wayland: contains packages that required wayland installed
- xorg: contains packages that required xorg installed
- extra: contains packages that can be built with or without either wayland and xorg

For `wayland` and `xorg` repo, you can choose either one or enabled both. If both is enabled, packages will be built against both. So you can have either 'pure wayland', 'pure xorg' or 'hybrid'.