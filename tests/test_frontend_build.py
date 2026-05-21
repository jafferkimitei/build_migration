import json
import os
import re
import subprocess
from pathlib import Path


TASK_ROOT = Path(os.environ.get("TASK_ROOT_FOR_TESTS", Path.cwd().parent)).resolve()
WORKSPACE_ROOT = Path(
    os.environ.get("WORKSPACE_ROOT_FOR_TESTS", TASK_ROOT / "workspace")
).resolve()


def read_text(relative_path: str) -> str:
    return (WORKSPACE_ROOT / relative_path).read_text()


def load_json(relative_path: str):
    return json.loads((WORKSPACE_ROOT / relative_path).read_text())


def test_package_typecheck_script_exists_and_is_used():
    package_json = load_json("package.json")
    scripts = package_json.get("scripts", {})

    assert "typecheck" in scripts
    assert "tsc -p tsconfig.json --noEmit" in scripts["typecheck"]
    assert scripts.get("build") == scripts["typecheck"]


def test_typescript_project_passes_strict_typecheck():
    result = subprocess.run(
        ["npm", "run", "typecheck", "--silent"],
        cwd=WORKSPACE_ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=45,
    )

    assert result.returncode == 0, result.stdout


def test_tsconfig_aliases_match_migrated_source_layout():
    tsconfig = load_json("tsconfig.json")
    paths = tsconfig["compilerOptions"]["paths"]

    assert paths["@/*"] == ["src/*"]
    assert paths["@lib/*"] == ["src/lib/*"]
    assert paths["@config/*"] == ["src/config/*"]
    assert paths["@ui/*"] == ["src/components/cards/*"]

    assert "src/utils/*" not in str(paths)
    assert "src/env/*" not in str(paths)


def test_dashboard_shell_uses_case_correct_component_imports():
    source = read_text("src/components/DashboardShell.ts")

    assert 'from "@ui/MetricCard"' in source
    assert 'from "@ui/StatusPill"' in source
    assert "@ui/status-pill" not in source


def test_public_environment_keeps_analytics_key_optional():
    source = read_text("src/config/env.ts")

    required_env_match = re.search(r"REQUIRED_ENV\s*=\s*\[(.*?)\]", source, re.S)
    assert required_env_match, "env.ts should define REQUIRED_ENV"

    required_env_body = required_env_match.group(1)
    assert "NEXT_PUBLIC_SITE_URL" in required_env_body
    assert "ANALYTICS_WRITE_KEY" not in required_env_body

    assert "analyticsKey?" in source
    assert "source.ANALYTICS_WRITE_KEY" in source


def test_metadata_builds_canonical_urls_without_double_slashes():
    source = read_text("src/lib/metadata.ts")

    assert "${env.siteUrl}/${input.path}" not in source
    assert "new URL" in source or "normalize" in source.lower() or "replace" in source

    assert "canonicalUrl" in source


def test_navigation_items_are_normalized_and_unique():
    source = read_text("src/lib/navigation.ts")

    assert source.count('label: "Dashboard"') == 1
    assert 'href: "reports"' not in source
    assert 'href: "/reports"' in source
    assert "new Set" in source or ".filter(" in source or "dedupe" in source.lower()


def test_route_manifest_preserves_root_and_normalizes_children():
    source = read_text("src/lib/routes.ts")

    assert 'route: "/"' in source
    assert 'route: "dashboard"' not in source
    assert 'route: "/dashboard"' in source
    assert 'route: "/reports/"' not in source
    assert 'route: "/reports"' in source

    assert 'route === "/"' in source or "if (route" in source


def test_no_legacy_alias_targets_remain_in_imports():
    source_files = list((WORKSPACE_ROOT / "src").rglob("*.ts"))
    combined = "\n".join(path.read_text() for path in source_files)

    assert "@lib/metadata" in combined
    assert "@config/env" in combined
    assert "@ui/MetricCard" in combined

    assert "src/utils" not in combined
    assert "src/env" not in combined
    assert "@ui/status-pill" not in combined
