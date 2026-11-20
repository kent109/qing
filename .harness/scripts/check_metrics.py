"""
确定性度量门禁（根据退出码驱动），是否放行本次编辑
"""

import ast, json, subprocess, sys
from pathlib import Path

CONFIG = json.loads((Path(".harness/configs/code_metrics.json")).read_text())


def check_class_metrics(filepath: Path) -> list[str]:
    tree = ast.parse(filepath.read_text())
    violations = []
    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef):
            methods = [
                n
                for n in node.body
                if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))
            ]
            if len(methods) > CONFIG["max_class_methods"]:
                violations.append(
                    f"{filepath}: 类 {node.name} 有 {len(methods)} 个方法 "
                    f"(上限 {CONFIG['max_class_methods']})"
                )
    return violations


def check_impact_gate() -> list[str]:
    result = subprocess.run(
        [
            "impact-gate",
            "score",
            "--mode",
            "worktree",
            "--block-at",
            str(CONFIG["impact_block_at"]),
            "--format",
            "json",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return [f"impact-gate 阻断: {result.stdout or result.stderr}"]
    return []


def main():
    violations = []
    for f in Path("app").rglob("*.py"):
        violations.extend(check_class_metrics(f))
    violations.extend(check_impact_gate())

    if violations:
        print("\n".join(violations))
        sys.exit(1)  # 非零退出码 = 门禁不通过
    print("代码度量门禁通过")
    sys.exit(0)


if __name__ == "__main__":
    main()
