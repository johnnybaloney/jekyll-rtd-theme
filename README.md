# About the Fork

## Summary

This fork of `jekyll-rtd-theme` offers a vastly improved build performance.

The original theme relies on Liquid for building the _Auto generated sidebar_. This results in very slow build times for larger sites.

Upgrading to Jekyll 4 improves the performance somewhat but the build time remains at an unacceptable level - build time reduction from over 2 minutes to 68 seconds on a test site.

Replacing Liquid with a Ruby plugin for generating the sidebar dramatically reduces the build time - build time reduction **from over 2 minutes to just 11 seconds** on a test site.

## Branches

This fork contains:
* `develop` - only containing an update to this document,
* `jekyll-4-port` - a Jekyll 4 port without GitHub Pages offering some performance benefits that come with the updated version of Jekyll,
* `sidebar-with-ruby-plugin` - developed on top of `jekyll-4-port` contains a Ruby plug-in that replaces Liquid templates for building the sidebar.

## Configuration

* Remove `Gemfile.lock` in the site project when switching theme branches and regenerate with:
    ```
    $ bundle update
    ```
* Specify the branch of the remote theme in site `_config.yaml`:
    ```
    remote_theme: johnnybaloney/jekyll-rtd-theme@<branch-name>
    ```
* Update the site `_config.yaml` with theme plugins etc.
* `jekyll-remote-theme` will not provide the custom plugin. It has to be included with the site files in the `_plugins` directory, Jekyll will discover it automatically:
    ```
    _plugins/render_sidebar.rb
    ```

## Benchmark

Tested on a sample site with 288 markdown files (including 64 README.md files).

### develop

Jekyll 3.9.0

```
$ bundle exec jekyll serve --profile

Filename                                                                            | Count |     Bytes |    Time
------------------------------------------------------------------------------------+-------+-----------+--------
jekyll-remote-theme-20210729-13391-1tgxa8n/_includes/templates/_toctree.liquid      |   230 | 28407.05K | 205.779
_layouts/default.liquid                                                             |   230 | 18192.14K | 102.650
jekyll-remote-theme-20210729-13391-1tgxa8n/_includes/templates/sidebar.liquid       |   230 | 10583.93K |  90.255
jekyll-remote-theme-20210729-13391-1tgxa8n/_includes/templates/toctree.liquid       |   230 | 10351.01K |  89.950
jekyll-remote-theme-20210729-13391-1tgxa8n/_includes/common/rest/workdir.liquid     |   262 |     0.00K |  47.739
jekyll-remote-theme-20210729-13391-1tgxa8n/_includes/common/rest/defaults.liquid    |   230 |     0.00K |   9.966
...
                    done in 122.048 seconds.
```

### jekyll-4-port

Jekyll 4.2.0

```
$ bundle exec jekyll serve --profile

| Filename                                                                            | Count |      Bytes |    Time |
+-------------------------------------------------------------------------------------+-------+------------+---------+
| jekyll-remote-theme-20210729-16437-1tiwpy2/_layouts/default.liquid                  |   230 |  19350.87K |  50.348 |
| jekyll-remote-theme-20210729-16437-1tiwpy2/_includes/templates/_toctree.liquid      |  8740 |  31544.62K |  48.723 |
| jekyll-remote-theme-20210729-16437-1tiwpy2/_includes/common/rest/site_pages.liquid  |   314 |      0.31K |  36.865 |
| jekyll-remote-theme-20210729-16437-1tiwpy2/_includes/common/rest/defaults.liquid    |   230 |     13.93K |  28.075 |
| jekyll-remote-theme-20210729-16437-1tiwpy2/_includes/templates/sidebar.liquid       |   230 |  11976.51K |  21.915 |
| jekyll-remote-theme-20210729-16437-1tiwpy2/_includes/templates/toctree.liquid       |   230 |  11743.59K |  21.902 |
| jekyll-remote-theme-20210729-16437-1tiwpy2/_includes/common/rest/workdir.liquid     |  9282 |    552.93K |  17.686 |
...
                    done in 68.658 seconds.
```

### sidebar-with-ruby-plugin

Jekyll 4.2.0 + sidebar rendering with a Ruby plugin rather than Liquid

```
$ bundle exec jekyll serve --profile

| Filename                                                                            | Count |     Bytes |   Time |
+-------------------------------------------------------------------------------------+-------+-----------+--------+
| jekyll-remote-theme-20210729-16758-1o7yw7q/_layouts/default.liquid                  |   230 | 16022.46K |  2.883 |
| search_data.json                                                                    |     1 |  2632.69K |  2.750 |
| jekyll-remote-theme-20210729-16758-1o7yw7q/_includes/common/rest/defaults.liquid    |   230 |     0.00K |  1.927 |
| jekyll-remote-theme-20210729-16758-1o7yw7q/_includes/common/rest/site_pages.liquid  |   265 |     0.00K |  1.738 |
...
                    done in 11.289 seconds.
```

# jekyll-rtd-theme

![CI](https://github.com/rundocs/jekyll-rtd-theme/workflows/CI/badge.svg?branch=develop)
![jsDelivr](https://data.jsdelivr.com/v1/package/gh/rundocs/jekyll-rtd-theme/badge)

Just another documentation theme compatible with GitHub Pages

## What it does?

This theme is inspired by [sphinx-rtd-theme](https://github.com/readthedocs/sphinx_rtd_theme) and refactored with:

- [@primer/css](https://github.com/primer/css)
- [github-pages](https://github.com/github/pages-gem) ([dependency versions](https://pages.github.com/versions/))

## Quick start

```yml
remote_theme: rundocs/jekyll-rtd-theme
```

You can [generate](https://github.com/rundocs/starter-slim/generate) with the same files and folders from [rundocs/starter-slim](https://github.com/rundocs/starter-slim/)

## Usage

Documentation that can guide how to create with Github pages, please refer to [rundocs.io](https://rundocs.io) for details

## Features

- Shortcodes (Toasts card, mermaid)
- Pages Plugins (emoji, gist, avatar, mentions)
- Auto generate sidebar
- [Attribute List Definitions](https://kramdown.gettalong.org/syntax.html#attribute-list-definitions) (Primer/css utilities, Font Awesome 4)
- Service worker (caches)
- SEO (404, robots.txt, sitemap.xml)
- Canonical Link (Open Graph, Twitter Card, Schema data)

## Options

| name          | default value        | description       |
| ------------- | -------------------- | ----------------- |
| `title`       | repo name            |                   |
| `description` | repo description     |                   |
| `url`         | user domain or cname |                   |
| `baseurl`     | repo name            |                   |
| `lang`        | `en`                 |                   |
| `direction`   | `auto`               | `ltr` or `rtl`    |
| `highlighter` | `rouge`              | Cannot be changed |

```yml
# folders sort
readme_index:
  with_frontmatter: true

meta:
  key1: value1
  key2: value2
  .
  .
  .

google:
  gtag:
  adsense:

mathjax: # this will prased to json, default: {}

mermaid:
  custom:     # mermaid link
  initialize: # this will prased to json, default: {}

scss:   # also _includes/extra/styles.scss
script: # also _includes/extra/script.js

translate:
  # shortcodes
  danger:
  note:
  tip:
  warning:
  # 404
  not_found:
  # copyright
  revision:
  # search
  searching:
  search:
  search_docs:
  search_results:
  search_results_found: # the "#" in this translate will replaced with results size!
  search_results_not_found:

plugins:
  - jemoji
  - jekyll-avatar
  - jekyll-mentions
```

## The license

The theme is available as open source under the terms of the MIT License
