import pytest

from pipelines import github_pipeline


def test_parse_repos_handles_list_and_strings(monkeypatch):
    # string input via env var
    monkeypatch.setenv("GITHUB_REPOS", "owner1/repo1, owner2/repo2")
    repos = github_pipeline._resolve_repos()
    assert repos == (("owner1", "repo1"), ("owner2", "repo2"))

    # config fallback when env var not set
    monkeypatch.delenv("GITHUB_REPOS", raising=False)
    monkeypatch.setenv("DLT_CONFIG_REPOS", "owner3/repo3")
    repos = github_pipeline._resolve_repos()
    assert repos == (("owner3", "repo3"),)


class _FakeSource(list):
    def with_resources(self, *_):
        return self


def _fake_github_reactions(*_args, **_kwargs):
    return _FakeSource([
        {
            "number": 1,
            "url": "https://example.com/pr/1",
            "title": "Test PR",
            "author__login": "tester",
            "state": "open",
        }
    ])


class _DummyPipeline:
    def __init__(self, *args, **kwargs):
        self.kwargs = kwargs
        self.runs = []

    def run(self, data):
        batch = list(data)
        self.runs.append(batch)
        class Result:
            loads_ids = ["test-load"]
        self.last_result = Result()
        return self.last_result


def test_pipeline_invocation(monkeypatch):
    monkeypatch.setenv("DLT_BUCKET_URL", "file:///tmp/dlt-test")
    monkeypatch.setattr(github_pipeline, "github_reactions", _fake_github_reactions)

    dummy = _DummyPipeline
    created = {}

    def _fake_pipeline(*args, **kwargs):
        created['pipeline'] = dummy(*args, **kwargs)
        return created['pipeline']

    monkeypatch.setattr(github_pipeline.dlt, "pipeline", _fake_pipeline)

    github_pipeline.load_pull_requests("owner", "repo")

    pipeline_instance = created['pipeline']
    assert pipeline_instance.kwargs["dataset_name"] == "owner_repo_pull_requests"
    assert pipeline_instance.runs[0][0]["title"] == "Test PR"
