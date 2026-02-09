class STWorkspace extends HTMLElement {
    constructor() {
        super();
        this.attachShadow({ mode: 'open' });
    }

    connectedCallback() {
        var evalUrl = this.getAttribute('eval-url') || '/eval';
        var showResult = this.hasAttribute('show-result');
        var initialCode = this.textContent.trim();
        this.textContent = '';

        var resultHtml = showResult
            ? '<div class="result-section">' +
              '    <label>Result:</label>' +
              '    <div class="result-box"></div>' +
              '</div>'
            : '';

        this.shadowRoot.innerHTML =
            '<style>' +
            ':host {' +
            '    display: block;' +
            '    background: white;' +
            '    border-radius: 8px;' +
            '    box-shadow: 0 2px 10px rgba(0,0,0,0.1);' +
            '    padding: 20px;' +
            '}' +
            'textarea {' +
            '    width: 100%;' +
            '    box-sizing: border-box;' +
            '    font-family: "SF Mono", Monaco, Menlo, Consolas, monospace;' +
            '    font-size: 14px;' +
            '    padding: 12px;' +
            '    border: 1px solid #ddd;' +
            '    border-radius: 4px;' +
            '    resize: vertical;' +
            '    min-height: 200px;' +
            '    background: #fafafa;' +
            '}' +
            'textarea:focus {' +
            '    outline: none;' +
            '    border-color: #007acc;' +
            '    box-shadow: 0 0 0 2px rgba(0,122,204,0.2);' +
            '}' +
            '.button-row {' +
            '    margin-top: 15px;' +
            '    display: flex;' +
            '    gap: 10px;' +
            '}' +
            'button {' +
            '    padding: 10px 24px;' +
            '    font-size: 14px;' +
            '    font-weight: bold;' +
            '    cursor: pointer;' +
            '    border: none;' +
            '    border-radius: 4px;' +
            '    transition: background 0.2s;' +
            '}' +
            '.eval-btn {' +
            '    background: #007acc;' +
            '    color: white;' +
            '}' +
            '.eval-btn:hover {' +
            '    background: #005a9e;' +
            '}' +
            '.clear-btn {' +
            '    background: #6c757d;' +
            '    color: white;' +
            '}' +
            '.clear-btn:hover {' +
            '    background: #545b62;' +
            '}' +
            '.result-section {' +
            '    margin-top: 20px;' +
            '}' +
            'label {' +
            '    display: block;' +
            '    font-weight: bold;' +
            '    margin-bottom: 8px;' +
            '    color: #555;' +
            '}' +
            '.result-box {' +
            '    background: #1e1e1e;' +
            '    color: #d4d4d4;' +
            '    padding: 15px;' +
            '    border-radius: 4px;' +
            '    font-family: "SF Mono", Monaco, Menlo, Consolas, monospace;' +
            '    font-size: 14px;' +
            '    min-height: 50px;' +
            '    white-space: pre-wrap;' +
            '    word-wrap: break-word;' +
            '}' +
            '</style>' +
            '<label>Enter Smalltalk code:</label>' +
            '<textarea></textarea>' +
            '<div class="button-row">' +
            '    <button class="eval-btn">Evaluate (Do it)</button>' +
            '    <button class="clear-btn">Clear</button>' +
            '</div>' +
            resultHtml;

        var textarea = this.shadowRoot.querySelector('textarea');
        var resultBox = this.shadowRoot.querySelector('.result-box');
        var evalBtn = this.shadowRoot.querySelector('.eval-btn');
        var clearBtn = this.shadowRoot.querySelector('.clear-btn');

        textarea.value = initialCode;

        function evaluate() {
            var start = textarea.selectionStart;
            var end = textarea.selectionEnd;
            var hasSelection = start !== end;
            var code = hasSelection ? textarea.value.substring(start, end) : textarea.value;

            var body = new URLSearchParams();
            body.append('code', code);

            fetch(evalUrl, { method: 'POST', body: body })
                .then(function(r) { return r.text(); })
                .then(function(result) {
                    if (resultBox) resultBox.textContent = result;
                    if (hasSelection) {
                        var insertion = ' ' + result;
                        textarea.setRangeText(insertion, end, end, 'select');
                        textarea.focus();
                    }
                });
        }

        evalBtn.addEventListener('click', evaluate);

        clearBtn.addEventListener('click', function() {
            textarea.value = '';
            textarea.focus();
        });

        textarea.addEventListener('keydown', function(e) {
            if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
                e.preventDefault();
                evaluate();
            }
        });
    }
}

customElements.define('st-workspace', STWorkspace);
