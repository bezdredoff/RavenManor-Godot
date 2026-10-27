# Raven Manor — загрузка больших патчей в GitHub с телефона

**Status:** *design + local security validator foundation*. Не заявлять, что автоматический importer, candidate PR или `/preview/` уже работают в Raven до merge ZIP workflow, одноразового bootstrap, GitHub permission проверки и успешного end-to-end теста. В UPDS похожий workflow уже реализован, но его npm-проверки и зависимости нельзя применять к Godot как есть.

## Когда использовать

- ChatGPT/DeepSeek не может отправить десятки файлов или большой binary patch через connector; авторизация GitHub недоступна; сгенерированы 3–4 связанных арт-ассета/ZIP для Room Builder/Godot.
- Для небольшой текстовой правки сохраняется прямой PR без загрузки ZIP.
- На телефоне: архив сохраняется в «Файлы» → GitHub web → ветка `incoming` → `incoming/<RM-task>_R<revision>.zip` → commit **только в incoming**, не в main. Использовать GitHub Pages `/preview/` только после настоящего ввода в эксплуатацию pipeline.

## Формат предпочтительного изменения (дельта)

```text
RM-CODE-02_R1.zip
├── patch-manifest.json
└── files/
    ├── scripts/...
    ├── docs/STATUS.md
    └── data/raven/production/production_progress.json
```

`patch-manifest.json`:
```json
{
  "format": "raven-delta-v1",
  "baseSha": "<40-hex SHA of RavenManor-Godot main at packaging>",
  "feature": "RM-CODE-02_R1",
  "taskIds": ["CODE-02-01"],
  "files": ["scripts/raven/...", "data/raven/production/production_progress.json"],
  "delete": []
}
```

Archive paths are relative POSIX paths with **no** absolute / ../ / symlinks. Runtime applies only if `baseSha` equals current main. For stale main, **fail closed** (a later `raven-delta-v2` may safely rebase after implementing path-conflict tests from UPDS); never overwrite newer paths. `files[]` plus `delete[]` declare exact content; undeclared payloads fail. All changes to task/status/docs should accompany code in the same ZIP.

## Security contract (mandatory before automation)

1. Max **25 MiB compressed** per ZIP (GitHub browser-friendly); max **250 MiB uncompressed**, max 1500 entries, reject duplicate normalized/case-fold paths, traversal, absolute/backslashes, symlinks, encrypted files, ZIP bombs, nested .git and code outputs.
2. Reject the protected paths: `.github/`, `AGENTS.md`, `CODEX.md`, `DEEPSEEK.md`, `CHATGPT.md`, `scripts/raven/tools/validate_mobile_patch.py`, ZIP-import automation itself, `docs/DECISIONS.md`, credentials, generated binaries, Never allow archive to change workflows/tests that validate it.
3. `production_progress.json` may be included in a candidate, but its claims of `accepted`, device QA or a merged PR are **not trusted automatically**. Every progress change requires normal human review and CI; import does not grant approval. Validate and apply on an isolated checkout with only `contents: read`; **no secrets, write-token or release credentials** present when inspecting or executing candidate code.
4. After validation of ZIP paths, **a distinct write-capable job** may create `candidate/*` branch + PR from exact validated main SHA. No untrusted process executed in write job. Actual Godot/tests run as separate low-privilege PR CI.
5. Candidate is **not** deployed directly to stable root; once isolated preview deployment is implemented, stable `/` is main, `/preview/` is one temporary candidate, separately cached and never intercepted by stable Service Worker.
6. Required: manual code review, GitHub Actions quality gate, relevant portrait device QA, provenance/license check, manual merge and rollback path. No auto-approve/auto-merge.
7. Public repo `incoming` archives are **public and remain recoverable in git history** without intentional cleanup. Never upload private bible/spoilers not approved for publication, personal data, keys, licensed models, purchased assets. On failure, invalidate/delete inbox tree, and rotate any leaked secret outside this pipeline (commits do not magically erase history).
8. Proposed `incoming` branch must be created from `main` only during pipeline bootstrap; no direct branch overwrite from phone. Subsequent changed ZIPs must be distinguishable; do not assume GitHub can upload >25 MiB.

## Current implementation stages

- **MOB-00**: security validator/test fixtures for `raven-delta-v1` in this planning PR; local validation takes archive and expected main SHA, rejects unsafe paths before extraction.
- **MOB-01**: bootstrap Actions `incoming` branch, separate read-only validation and write-capable candidate PR with protected files/permissions, stale-base checks. This is **not delivered** by mere description.
- **MOB-02**: independent Godot PR CI; isolated artifact from validated candidate; no script execution in a write-token job.
- **MOB-03**: safe GitHub Pages `/preview/` packaging with stable main root and separate SW/cache scope; preview auto-expiry/rollback.
- **MOB-04**: end-to-end phone upload, invalid ZIP attacks, stale SHA, PR creation, iPhone/Android viewport test, manual merge → stable deploy proof.

Отсутствие MOB-01–04 не означает, что ChatGPT не может подготовить готовый ZIP для ручной загрузки в будущий pipeline. Отдельный PR потребуется для security-reviewed GitHub Actions. Можно воспользоваться direct connector PR небольших файлов до активации importer. **Статус MOB-01–04 должен быть явно отображён в production dashboard, без ложных «готово».**
