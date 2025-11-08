"""Github pull-request ingestion entrypoints."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Iterable, Sequence, Tuple

import dlt
from dlt.destinations import filesystem
from github import github_reactions


DEFAULT_REPOS: Tuple[Tuple[str, str], ...] = (
    ("dlt-hub", "dlt"),
)


def _filesystem_destination() -> filesystem:
    bucket_url = os.environ.get("DLT_BUCKET_URL")
    if not bucket_url:
        bucket_url = dlt.config.get("pipeline.bucket_url", None)
    if not bucket_url:
        raise RuntimeError(
            "Provide a bucket URL via DLT_BUCKET_URL or pipeline.bucket_url in config."
        )

    return filesystem(bucket_url=bucket_url, file_format="json")


def load_pull_requests(org: str, repo: str, *, max_items: int | None = None) -> None:
    """Ingest pull-request records for a single Github repository."""

    dataset_name = f"{org}_{repo}_pull_requests".replace("-", "_")
    pipeline = dlt.pipeline(
        pipeline_name=f"github_pr_{org}_{repo}",
        destination=_filesystem_destination(),
        dataset_name=dataset_name,
    )

    data = github_reactions(org, repo, max_items=max_items).with_resources("pull_requests")
    run_info = pipeline.run(data)
    print(run_info)


def run_for_repositories(repos: Iterable[Tuple[str, str]], max_items: int | None = None) -> None:
    for org, repo in repos:
        load_pull_requests(org, repo, max_items=max_items)


def _parse_repos(raw: str | Sequence[str] | None) -> Tuple[Tuple[str, str], ...]:
    if not raw:
        return DEFAULT_REPOS

    if isinstance(raw, str):
        items = [chunk.strip() for chunk in raw.split(",") if chunk.strip()]
    else:
        items = [chunk.strip() for chunk in raw if chunk.strip()]

    parsed = []
    for owner_repo in items:
        if "/" not in owner_repo:
            raise ValueError(f"Malformed repo '{owner_repo}'. Expected 'owner/repo'.")
        owner, repo = owner_repo.split("/", 1)
        parsed.append((owner.strip(), repo.strip()))
    return tuple(parsed)


def _resolve_repos() -> Tuple[Tuple[str, str], ...]:
    env_repos = os.environ.get("GITHUB_REPOS")
    if env_repos:
        return _parse_repos(env_repos)

    config_repos = os.environ.get("DLT_CONFIG_REPOS")
    if config_repos:
        return _parse_repos(config_repos)

    repos_from_file = dlt.config.get("pipeline.repos", None)
    if repos_from_file:
        return _parse_repos(repos_from_file)

    return DEFAULT_REPOS


if __name__ == "__main__":
    repos = _resolve_repos()
    max_items_env = os.environ.get("GITHUB_MAX_ITEMS")
    max_items = int(max_items_env) if max_items_env else None
    run_for_repositories(repos, max_items=max_items)
