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


def test_dashboard_shell_uses_case_safe_ui_imports():
    source = read_text("src/components/DashboardShell.ts")

    assert "@ui/status-pill" not in source
    assert "status-pill" not in source
    assert "@ui/" in source


def test_public_environment_keeps_analytics_key_optional():
    source = read_text("src/config/env.ts")

    assert "NEXT_PUBLIC_SITE_URL" in source
    assert "ANALYTICS_WRITE_KEY" in source
    assert "analyticsKey?" in source

    assert not re.search(r"if\s*\(\s*!source\.ANALYTICS_WRITE_KEY\s*\)", source)
    assert "Missing required environment variable: ANALYTICS_WRITE_KEY" not in source


def test_metadata_avoids_direct_slash_concatenation_for_canonical_urls():
    source = read_text("src/lib/metadata.ts")

    assert "canonicalUrl" in source
    assert "${env.siteUrl}/${input.path}" not in source
    assert ".replace(" in source or "URL(" in source or "normalize" in source.lower()


def test_navigation_source_has_unique_normalized_visible_links():
    source = read_text("src/lib/navigation.ts")

    assert source.count('label: "Dashboard"') == 1
    assert 'href: "reports"' not in source
    assert 'href: "/reports"' in source


def test_route_manifest_preserves_root_and_normalizes_children():
    source = read_text("src/lib/routes.ts")

    assert 'route: "/"' in source
    assert 'route: "dashboard"' not in source
    assert 'route: "/dashboard"' in source
    assert 'route: "/reports/"' not in source
    assert 'route: "/reports"' in source


def test_no_legacy_alias_targets_remain_in_source():
    source_files = list((WORKSPACE_ROOT / "src").rglob("*.ts"))
    combined = "\n".join(path.read_text() for path in source_files)

    assert "src/utils" not in combined
    assert "src/env" not in combined
    assert "@ui/status-pill" not in combined
