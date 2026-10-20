# Local security patch (2026-10-20)

Based on jQuery Validation 1.21.0. `clean` resolves selectors, DOM nodes and jQuery
objects against existing fields inside the current form. `validationTargetFor`
uses that resolver before filtering. HTML strings cannot construct new elements.
Both the source and minified distribution include this patch.

Regression checks: `npm ci --ignore-scripts && npm test` from the repository root.
Reapply or replace this fix when refreshing the vendored library; do not overwrite
only one distribution file. Server-side validation remains authoritative.
