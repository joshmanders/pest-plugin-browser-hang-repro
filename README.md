# pest-plugin-browser hang reproduction

A stock Laravel 13 + Pest 5 React starter kit, used to reproduce two ways
`Pest\Browser\Playwright\Client::execute()` can hang forever.

Both come from the same unbounded `while (true)` loop in that method, which has no
timeout, no cancellation and no branch for a connection that has gone away.

| | symptom | trigger |
| --- | --- | --- |
| A | 100% CPU, process state `R`, forever | the WebSocket connection closes mid-request |
| B | 0% CPU, process state `S`, forever | an action on a locator that matches nothing ([pestphp/pest#1781](https://github.com/pestphp/pest/issues/1781)) |

## Setup

```bash
composer install
npm install
npx playwright install chromium
npm run build
```

`package.json` pins `playwright` so you can swap versions to compare:

```bash
npm i -D playwright@1.62.0 && npx playwright install chromium   # or 1.61.1
```

## A — connection closes mid-request

```bash
./repro.sh hang 3 --filter='never appears'
```

The script starts the suite, kills the Playwright server three seconds in, then reports
whether Pest noticed. Unpatched it prints `VERDICT: HANG` and shows the process pinned at
~100% CPU in state `R` until the script kills it.

This one is **not version specific** — it reproduces identically on playwright 1.61.1 and
1.62.0. `fetch()` casts the `null` that `receive()` returns on a closed connection to `''`,
which decodes to `null`, which has neither an `error` key to throw on nor an `id` key to
break on, so the loop spins without ever blocking.

## B — action on a zero-match locator

```bash
./vendor/bin/pest --filter='zero-match'
```

| playwright | result |
| --- | --- |
| 1.61.1 | fails with `Timeout 5000ms exceeded` after ~10s |
| 1.62.0 | hangs forever at 0% CPU |

Playwright 1.62.0 ([microsoft/playwright#41712](https://github.com/microsoft/playwright/pull/41712))
moved the timeout off each method's params onto the protocol-level `metadata`, where an
absent value means *no timeout at all*. The plugin sends the timeout only in `params`, so a
1.62.0 server is told the action has no deadline and waits forever.

## Notes

- `tests/Browser/WelcomeTest.php` is a passing control — browser testing itself works fine.
- Neither hang needs `--parallel`; a single test reproduces both.
- Load alone does not reproduce them: 60 browser tests under `--parallel` against a healthy
  server complete in ~11s.

## Related

- [pestphp/pest#1781](https://github.com/pestphp/pest/issues/1781) — symptom B
- [microsoft/playwright#42046](https://github.com/microsoft/playwright/issues/42046) — closed as out of scope, correctly; the protocol change was intentional
