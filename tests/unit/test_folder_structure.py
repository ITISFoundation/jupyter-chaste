# pylint:disable=unused-variable
# pylint:disable=unused-argument
# pylint:disable=redefined-outer-name

from pathlib import Path

import pytest

expected_files = (
    "metadata:metadata.yml",
    "docker:*.bash",
    "docker/run_health_check.py",
    "tools/update_compose_labels.py",
    "versioning:*.cfg",
    "requirements-dev.in",
    "requirements-dev.txt",
    "Makefile",
    "VERSION",
    "VERSION_INTEGRATION",
    "README.md",
    "docker-compose-build.yml",
    "docker-compose-meta.yml",
    "docker-compose.yml",
)


@pytest.mark.parametrize("expected_path", expected_files)
def test_path_in_repo(expected_path: str, project_slug_dir: Path):

    if ":" in expected_path:
        folder, glob = expected_path.split(":")
        folder_path = project_slug_dir / folder
        assert folder_path.exists(), f"folder {folder_path} is missing!"
        assert any(folder_path.glob(glob)), f"no {glob} in {folder_path}"
    else:
        assert (
            project_slug_dir / expected_path
        ).exists(), f"{expected_path} is missing from {project_slug_dir}"
