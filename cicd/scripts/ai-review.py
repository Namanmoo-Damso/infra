import json
import os
import sys

import boto3
import requests

# 환경 변수 로드
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
PR_NUMBER = os.environ.get("PR_NUMBER")
REPO = os.environ.get("REPO")
AWS_REGION = os.environ.get("AWS_REGION", "ap-northeast-1")  # 기본값 도쿄

# Bedrock 모델 ID (Claude Sonnet 4.5)
# AWS 콘솔 > Bedrock > Model access에서 해당 모델 사용 권한이 켜져 있어야 합니다.
MODEL_ID = "anthropic.claude-sonnet-4-5-20250929-v1:0"


def get_pr_diff():
    """GitHub API를 통해 PR의 변경사항(Diff)을 가져옵니다."""
    url = f"https://api.github.com/repos/{REPO}/pulls/{PR_NUMBER}"
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3.diff",  # Diff 형식으로 요청
    }
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return response.text


def analyze_code_with_bedrock(diff_content):
    """AWS Bedrock을 사용하여 코드를 분석합니다."""
    bedrock = boto3.client(service_name="bedrock-runtime", region_name=AWS_REGION)

    # 프롬프트
    prompt = f"""
    You are a senior software engineer. Please review the following code changes (git diff).

    Your review MUST follow this structure in Korean:

    ## 1. 전체적인 리뷰 요약
    (Brief summary of the changes and code quality)

    ## 2. 변경 제안/요청 리스트
    - (1-line summary of suggestion 1)
    - (1-line summary of suggestion 2)
    ...

    ## 3. 상세 제안 (As-Is vs To-Be)
    For each suggestion, provide:
    ### (Title of Suggestion)
    - **설명:** (Why this change is needed)
    - **As-Is (기존 코드):**
    ```
    (Original code)
    ```
    - **To-Be (제안 코드):**
    ```
    (Proposed code)
    ```

    Focus on:
    1. Potential bugs or logic errors.
    2. Security vulnerabilities.
    3. Code style and best practices.
    4. Performance improvements.

    Please provide your review in **Korean** (한국어).
    If the code looks good, just say "LGTM (Looks Good To Me)".

    Code changes:
    {diff_content[:50000]}
    """
    # 토큰 제한을 고려해 diff 내용을 50,000자로 제한

    body = json.dumps(
        {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 4096,
            "messages": [{"role": "user", "content": prompt}],
        }
    )

    try:
        response = bedrock.invoke_model(
            body=body,
            modelId=MODEL_ID,
            accept="application/json",
            contentType="application/json",
        )
        response_body = json.loads(response.get("body").read())
        return response_body["content"][0]["text"]
    except Exception as e:
        print(f"Error invoking Bedrock: {e}")
        return None


def post_comment(comment_body):
    """GitHub PR에 코멘트를 등록합니다."""
    url = f"https://api.github.com/repos/{REPO}/issues/{PR_NUMBER}/comments"
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json",
    }
    data = {"body": comment_body}
    response = requests.post(url, headers=headers, json=data)
    response.raise_for_status()


def main():
    if not all([GITHUB_TOKEN, PR_NUMBER, REPO]):
        print("Error: Missing environment variables.")
        sys.exit(1)

    print(f"Starting AI Review for PR #{PR_NUMBER} in {REPO}...")

    # 1. Diff 가져오기
    try:
        diff = get_pr_diff()
        if not diff.strip():
            print("No changes found in this PR.")
            sys.exit(0)
    except Exception as e:
        print(f"Failed to fetch PR diff: {e}")
        sys.exit(1)

    # 2. Bedrock 분석 요청
    print("Analyzing code with AWS Bedrock...")
    review_result = analyze_code_with_bedrock(diff)

    if not review_result:
        print("Failed to get review from Bedrock.")
        sys.exit(1)

    # 3. 코멘트 등록
    print("Posting comment to GitHub...")
    try:
        formatted_comment = (
            f"## 🤖 AI Code Review (Claude Sonnet 4.5)\n\n{review_result}"
        )
        post_comment(formatted_comment)
        print("Review posted successfully!")
    except Exception as e:
        print(f"Failed to post comment: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
