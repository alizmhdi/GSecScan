# GSecScan

GSecScan is a tool for detecting secrets like passwords, API keys, and tokens in a gitlab instance.

## Install

1. Install `git`, `jq`, `curl` and [`gitleaks`](https://github.com/gitleaks/gitleaks).

2. Clone the repository in add `GSecScan` path to your $PATH.

## Usage

```
GSecScan <GITLAB_URL> <GITLAB_ACCESS_TOKEN>
```

NOTE: To run GSecScan you should have a gitlab access toke. You can use this [like](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) to generate gitlab access token.