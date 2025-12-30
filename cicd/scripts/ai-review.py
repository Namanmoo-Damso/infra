import json
import os
import sys
from datetime import datetime

import boto3
import requests

# 환경 변수 로드
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
PR_NUMBER = os.environ.get("PR_NUMBER")
REPO = os.environ.get("REPO")
BEDROCK_REGION = "us-east-1"
S3_REGION = os.environ.get("S3_REGION", "ap-northeast-2")
S3_BUCKET_NAME = os.environ.get(
    "S3_BUCKET_NAME", "krafton-jg-namanmoo-ai-pr-reviews"
)  # 리뷰를 저장할 버킷

# Bedrock 모델 ID (Claude Sonnet 4.5)
MODEL_ID = "global.anthropic.claude-sonnet-4-5-20250929-v1:0"


def get_pr_details():
    """PR의 상세 정보(제목, 작성자, 링크)를 가져옵니다."""
    url = f"https://api.github.com/repos/{REPO}/pulls/{PR_NUMBER}"
    headers = {"Authorization": f"token {GITHUB_TOKEN}"}
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return response.json()


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
    bedrock = boto3.client(service_name="bedrock-runtime", region_name=BEDROCK_REGION)

    # 프롬프트
    prompt = f"""
    You are a senior software engineer. Please review the following code changes (git diff).

    Your review MUST follow this structure in Korean:

    ## 1. 전체적인 리뷰 요약
    (Brief summary of the changes and code quality)

    ## 2. 🚨 중요 이슈 (Critical)
    List critical issues that MUST be fixed (bugs, security vulnerabilities, logic errors).
    - [ ] (1-line summary)
    - [ ] (1-line summary)
    (If none, write "발견된 중요 이슈 없음")

    ## 3. 💡 개선 제안 (Minor)
    List suggestions for improvement (code style, performance, readability).
    - [ ] (1-line summary)
    - [ ] (1-line summary)

    ## 4. 상세 설명 (As-Is vs To-Be)
    For each suggestion, use the following HTML collapsible format:

    <details>
    <summary>🚨 or💡 <strong>(Title of Suggestion)</strong></summary>

    - **설명:** (Why this change is needed)

    - **As-Is (기존 코드):**
    ```language
    (Original code)
    ```
    - **To-Be (제안 코드):**
    ```language
    (Proposed code)
    ```
    </details>

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


def save_review_to_s3(review_content, pr_details):
    """리뷰 내용을 S3 버킷에 마크다운 파일로 저장합니다."""
    if not S3_BUCKET_NAME:
        print("Skipping S3 upload: S3_BUCKET_NAME not set.")
        return

    s3 = boto3.client("s3", region_name=S3_REGION)

    # 파일명: reviews/레포명/작성자/날짜_PR번호.md
    date_str = datetime.now().strftime("%Y-%m-%d")
    repo_name = REPO.split("/")[-1]
    author = pr_details["user"]["login"]
    file_key = f"reviews/{repo_name}/{author}/{date_str}_PR-{PR_NUMBER}.md"

    # 마크다운 내용 구성
    archive_content = f"""# AI Review Log

- **저장소:** {REPO}
- **PR:** [#{PR_NUMBER}: {pr_details["title"]}]({pr_details["html_url"]})
- **작성자:** {pr_details["user"]["login"]}
- **This review created at:** {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

---

{review_content}
"""

    try:
        s3.put_object(
            Bucket=S3_BUCKET_NAME,
            Key=file_key,
            Body=archive_content.encode("utf-8"),
            ContentType="text/markdown",
        )
        print(f"Review archived to s3://{S3_BUCKET_NAME}/{file_key}")
    except Exception as e:
        print(f"Failed to upload to S3: {e}")


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

        pr_details = get_pr_details()
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

        # S3 저장
        save_review_to_s3(review_result, pr_details)
        print("Review saved into s3 successfully!")

    except Exception as e:
        print(f"Failed to process review: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
