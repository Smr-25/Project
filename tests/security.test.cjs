const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const { JSDOM } = require('jsdom');
const lib = join(__dirname, '../RestoranApp/src/RestaurantApp.Web/wwwroot/lib');

for (const suffix of ['', '.min']) {
    test(`validation${suffix} accepts form fields but never constructs HTML from a selector`, () => {
        const dom = new JSDOM('<form><input name="Email" id="Email" required></form>', {
            url: 'https://example.test/', runScripts: 'outside-only'
        });
        try {
            const w = dom.window;
            w.eval(readFileSync(join(lib, `jquery/dist/jquery${suffix}.js`), 'utf8'));
            w.eval(readFileSync(join(lib, `jquery-validation/dist/jquery.validate${suffix}.js`), 'utf8'));
            const $ = w.jQuery;
            const validator = $('form').validate({ ignore: '' });
            const field = w.document.getElementById('Email');
            assert.equal(validator.clean('#Email'), field);
            assert.equal(validator.validationTargetFor(field), field);
            assert.equal(validator.element(field), false);
            field.value = 'person@example.test';
            assert.equal(validator.element(field), true);
            for (const method of ['clean', 'validationTargetFor']) {
                assert.throws(() => validator[method]('<img src=x onerror="window.attacked=true">'));
            }
            assert.equal(w.document.querySelectorAll('img, [onerror]').length, 0);
            assert.equal(w.attacked, undefined);
            // jQuery's selector feature-test IDs contain no external input.
            assert.match($.expando, /^jQuery[0-9]+$/);
        } finally { dom.window.close(); }
    });
}
