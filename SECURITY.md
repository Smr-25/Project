# Təhlükəsizlik siyasəti

Zəiflik tapsanız, lütfən public issue açmayın. Bu repo-nun "Security" bölməsindəki
"Report a vulnerability" düyməsi ilə məxfi şəkildə bildirin.

## Reviewed CodeQL findings (2026-10-20)

The two `js/xss-through-dom` findings in jQuery 3.7.1's selector feature detection
use `jQuery.expando`, initialized from the fixed version string and `Math.random()`
with all non-digits removed. Neither value comes from a request, URL, form,
storage or application data. They are false positives, not an encoding bypass.
The vendored jQuery source is unchanged; no scan paths or rules are excluded.

The separate jQuery Validation selector findings are fixed in both distribution
files; see its `SECURITY-PATCH.md` and the root `npm test` regression checks.
Server-side antiforgery checks are explicit on each POST and covered by HTTP tests.
