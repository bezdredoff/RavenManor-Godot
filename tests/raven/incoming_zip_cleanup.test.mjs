import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const workflow = readFileSync(new URL('../../.github/workflows/import-mobile-zip.yml', import.meta.url), 'utf8');
const marker = '      - name: Remove only archives from the triggering incoming snapshot';
const start = workflow.indexOf(marker);
assert.ok(start >= 0, 'cleanup step exists');
const lines = workflow.slice(start).split('\n');
const scriptStart = lines.indexOf('          script: |');
assert.ok(scriptStart >= 0, 'github-script program exists');
const codeLines = [];
for (const line of lines.slice(scriptStart + 1)) {
  if (line.trim() && !line.startsWith('            ')) break;
  codeLines.push(line.startsWith('            ') ? line.slice(12) : '');
}
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
const cleanup = new AsyncFunction('context', 'github', 'core', 'process', codeLines.join('\n'));
const snapshot = 'a'.repeat(40);

function harness({ names = ['incoming/one.zip'], head = snapshot, event = 'push',
                   manualPath = '', mutateAfterFirstDelete = false, changedBlob = '' } = {}) {
  const records = names.map((path, i) => ({
    type: 'file', path, name: path.split('/').at(-1), sha: String(i + 1).repeat(40),
  }));
  const active = new Map(records.map(x => [x.path, { ...x }]));
  const deleted = [];
  const warnings = [];
  let liveHead = head;
  const github = { rest: {
    git: { getRef: async () => ({ data: { object: { sha: liveHead } } }) },
    repos: {
      getContent: async ({ path, ref }) => {
        if (path === 'incoming') return { data: records };
        const item = active.get(path);
        if (!item) throw Object.assign(new Error('not found'), { status: 404 });
        return { data: { ...item, sha: changedBlob || item.sha } };
      },
      deleteFile: async ({ path, sha, branch }) => {
        assert.equal(branch, 'incoming');
        assert.equal(active.get(path)?.sha, sha, 'deletion must use the snapshot blob SHA');
        deleted.push(path);
        active.delete(path);
        liveHead = mutateAfterFirstDelete && deleted.length === 1
          ? 'external-head' : 'our-commit-' + deleted.length;
        return { data: { commit: { sha: 'our-commit-' + deleted.length } } };
      },
    },
  }};
  const context = { repo: { owner: 'bezdredoff', repo: 'RavenManor-Godot' },
                    eventName: event, sha: snapshot, runId: 88 };
  const core = { info: () => {}, warning: x => warnings.push(x) };
  return { run: () => cleanup(context, github, core, { env: { INPUT_ARCHIVE: manualPath } }),
           deleted, warnings, active };
}

test('GitHub Actions cleanup job is nested under jobs, not a root YAML key', () => {
  assert.match(workflow, /^jobs:[ \t]*$/m);
  assert.match(workflow, /^  cleanup_incoming_zip:[ \t]*$/m);
  assert.doesNotMatch(workflow, /^cleanup_incoming_zip:[ \t]*$/m);
  assert.match(workflow, /^    needs: \[validate, candidate, test_candidate\][ \t]*$/m);
});

test('cleanup runs despite failed validate/candidate/test jobs', async () => {
  assert.match(workflow, /needs: \[validate, candidate, test_candidate\]/);
  assert.match(workflow, /if: \$\{\{ always\(\) && github\.ref == 'refs\/heads\/incoming' \}\}/);
  const h = harness({ names: ['incoming/broken.zip', 'incoming/earlier.zip'] });
  await h.run();
  assert.deepEqual(h.deleted, ['incoming/broken.zip', 'incoming/earlier.zip']);
});
test('success also removes the uploaded ZIP', async () => {
  const h = harness(); await h.run();
  assert.deepEqual(h.deleted, ['incoming/one.zip']);
});
test('new incoming head never loses its newer upload', async () => {
  const h = harness({ head: 'newer-user-commit' }); await h.run();
  assert.deepEqual(h.deleted, []);
  assert.ok(h.warnings.some(x => x.includes('advanced')));
});
test('concurrent push during multi-archive cleanup stops later deletion', async () => {
  const h = harness({ names: ['incoming/one.zip', 'incoming/two.zip'],
                      mutateAfterFirstDelete: true });
  await h.run();
  assert.deepEqual(h.deleted, ['incoming/one.zip']);
  assert.ok(h.warnings.some(x => x.includes('changed during cleanup')));
});
test('changed blob and foreign paths are never deleted', async () => {
  const h = harness({ names: ['incoming/one.zip', 'incoming/not-a-file.txt', 'other/evil.zip'],
                      changedBlob: 'different' });
  await h.run();
  assert.deepEqual(h.deleted, []);
});
test('manual dispatch removes only the specified archive', async () => {
  const h = harness({ names: ['incoming/a.zip', 'incoming/b.zip'],
                      event: 'workflow_dispatch', manualPath: 'incoming/b.zip' });
  await h.run();
  assert.deepEqual(h.deleted, ['incoming/b.zip']);
});
test('manual dispatch refuses noncanonical archive path', async () => {
  const h = harness({ event: 'workflow_dispatch', manualPath: 'incoming/../main.yml' });
  await assert.rejects(h.run(), /valid incoming/);
  assert.deepEqual(h.deleted, []);
});
test('empty incoming snapshot is a harmless no-op', async () => {
  const h = harness({ names: [] }); await h.run();
  assert.deepEqual(h.deleted, []);
});
