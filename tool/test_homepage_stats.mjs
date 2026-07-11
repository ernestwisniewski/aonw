import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createContext, runInContext} from 'node:vm';

const statsPageUrl = new URL(
  '../deploy/homepage/stats/index.html',
  import.meta.url,
);
const statsPage = readFileSync(statsPageUrl, 'utf8');
const scriptMatches = [
  ...statsPage.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi),
];

assert.equal(
  scriptMatches.length,
  1,
  'The stats page must contain exactly one inline runtime script.',
);

const statsScript = scriptMatches[0][1];
assert.doesNotMatch(
  statsScript,
  /\b(?:innerHTML|outerHTML)\b/,
  'Stats data must not be rendered through an HTML parsing sink.',
);

const pageIds = [...statsPage.matchAll(/\bid="([^"]+)"/g)].map(
  (match) => match[1],
);
assert.equal(
  new Set(pageIds).size,
  pageIds.length,
  'The stats page must not contain duplicate element IDs.',
);

class FakeElement {
  constructor(harness, tagName = 'div', id = '') {
    this.harness = harness;
    this.tagName = tagName.toUpperCase();
    this.id = id;
    this.hidden = false;
    this.disabled = false;
    this.children = [];
    this.attributes = new Map();
    this.listeners = new Map();
    this._textContent = '';
  }

  get textContent() {
    return this._textContent;
  }

  set textContent(value) {
    this._textContent = String(value);
    this.children = [];
  }

  get innerHTML() {
    return '';
  }

  set innerHTML(value) {
    this.harness.htmlWrites.push({element: this, property: 'innerHTML', value});
    throw new Error('Unsafe innerHTML write detected.');
  }

  get outerHTML() {
    return '';
  }

  set outerHTML(value) {
    this.harness.htmlWrites.push({element: this, property: 'outerHTML', value});
    throw new Error('Unsafe outerHTML write detected.');
  }

  append(...children) {
    this.children.push(...children);
  }

  replaceChildren(...children) {
    this.children = [...children];
    this._textContent = '';
  }

  setAttribute(name, value) {
    this.attributes.set(name, String(value));
  }

  getAttribute(name) {
    return this.attributes.get(name) ?? null;
  }

  addEventListener(type, listener) {
    const listeners = this.listeners.get(type) ?? [];
    listeners.push(listener);
    this.listeners.set(type, listeners);
  }

  click() {
    if (this.disabled) return;
    for (const listener of this.listeners.get('click') ?? []) {
      listener({currentTarget: this, target: this, type: 'click'});
    }
  }
}

class StatsHarness {
  constructor(fetchImplementation) {
    this.fetchImplementation = fetchImplementation;
    this.fetchCalls = [];
    this.htmlWrites = [];
    this.createdElements = [];
    this.intervalRegistrations = [];
    this.timeoutRegistrations = [];
    this.windowListeners = new Map();
    this.documentListeners = new Map();
    this.nextTimerId = 1;

    this.elements = new Map(
      pageIds.map((id) => [id, this.createElement('div', id)]),
    );

    this.document = {
      visibilityState: 'visible',
      getElementById: (id) => this.elements.get(id) ?? null,
      querySelectorAll: () => [],
      createElement: (tagName) => this.createElement(tagName),
      createElementNS: (_namespace, tagName) => this.createElement(tagName),
      addEventListener: (type, listener) => {
        this.documentListeners.set(type, listener);
      },
    };

    this.window = {
      setTimeout: (callback, milliseconds) => {
        const id = this.nextTimerId++;
        this.timeoutRegistrations.push({id, callback, milliseconds});
        return id;
      },
      clearTimeout: (id) => {
        this.timeoutRegistrations = this.timeoutRegistrations.filter(
          (registration) => registration.id !== id,
        );
      },
      setInterval: (callback, milliseconds) => {
        const id = this.nextTimerId++;
        this.intervalRegistrations.push({id, callback, milliseconds});
        return id;
      },
      clearInterval: (id) => {
        this.intervalRegistrations = this.intervalRegistrations.filter(
          (registration) => registration.id !== id,
        );
      },
      addEventListener: (type, listener) => {
        this.windowListeners.set(type, listener);
      },
    };

    this.context = createContext({
      AbortController,
      Array,
      Date,
      DOMException,
      Error,
      Intl,
      Math,
      Number,
      Object,
      Promise,
      RegExp,
      Set,
      String,
      TypeError,
      document: this.document,
      fetch: (url, options) => {
        this.fetchCalls.push({url, options});
        return this.fetchImplementation(url, options);
      },
      window: this.window,
    });
  }

  createElement(tagName, id = '') {
    const element = new FakeElement(this, tagName, id);
    this.createdElements.push(element);
    return element;
  }

  execute() {
    runInContext(statsScript, this.context, {
      filename: 'deploy/homepage/stats/index.html#inline-script',
    });
  }

  fireTimeout(milliseconds) {
    const registration = this.timeoutRegistrations.find(
      (candidate) => candidate.milliseconds === milliseconds,
    );
    assert.ok(registration, `Expected a ${milliseconds}ms timeout registration.`);
    this.timeoutRegistrations = this.timeoutRegistrations.filter(
      (candidate) => candidate.id !== registration.id,
    );
    registration.callback();
  }

  element(id) {
    const element = this.elements.get(id);
    assert.ok(element, `Expected stats page element #${id}.`);
    return element;
  }
}

function responseWith(payload, {ok = true, status = 200} = {}) {
  return {
    ok,
    status,
    json: async () => payload,
  };
}

function buildActivity({empty = false} = {}) {
  const firstDay = Date.UTC(2026, 5, 13);
  return Array.from({length: 30}, (_, index) => ({
    date: new Date(firstDay + index * 86_400_000).toISOString().slice(0, 10),
    started: empty ? 0 : (index % 5) + 1,
    completed: empty ? 0 : index % 4,
  }));
}

function buildSnapshot({empty = false} = {}) {
  return {
    schemaVersion: 1,
    generatedAt: '2026-07-12T10:00:00.000Z',
    windowDays: 30,
    totals: {
      activeSessions: empty ? 0 : 12,
      openLobbies: empty ? 0 : 4,
      matchesStarted: empty ? 0 : 184,
      matchesCompleted: empty ? 0 : 131,
      matchesAbandoned: empty ? 0 : 17,
    },
    activity: buildActivity({empty}),
    turns: {
      averageCompleted: empty ? 0 : 47.6,
      longestCompleted: empty ? 0 : 163,
      totalPlayed: empty ? 0 : 8421,
      distribution: [
        {label: '1–10', count: empty ? 0 : 6},
        {label: '11–25', count: empty ? 0 : 22},
        {label: '26–50', count: empty ? 0 : 48},
        {label: '51–100', count: empty ? 0 : 39},
        {label: '101+', count: empty ? 0 : 16},
      ],
    },
    outcomes: [
      {condition: 'conquest', count: empty ? 0 : 37},
      {condition: 'domination', count: empty ? 0 : 24},
      {condition: 'cultural', count: empty ? 0 : 19},
      {condition: 'score', count: empty ? 0 : 31},
      {condition: 'draw', count: empty ? 0 : 8},
      {condition: 'resignation', count: empty ? 0 : 12},
    ],
  };
}

async function waitFor(predicate, description, timeoutMilliseconds = 1000) {
  const deadline = Date.now() + timeoutMilliseconds;
  while (Date.now() < deadline) {
    if (predicate()) return;
    await new Promise((resolve) => setTimeout(resolve, 5));
  }
  throw new Error(`Timed out waiting for ${description}.`);
}

function allText(elements) {
  const text = [];
  const visit = (element) => {
    text.push(element.textContent);
    for (const child of element.children) {
      if (child instanceof FakeElement) visit(child);
    }
  };
  for (const element of elements) visit(element);
  return text;
}

async function testPopulatedContractAndLoading() {
  let resolveFetch;
  const pendingResponse = new Promise((resolve) => {
    resolveFetch = resolve;
  });
  const harness = new StatsHarness(() => pendingResponse);
  harness.execute();

  assert.equal(harness.element('loading-state').hidden, false);
  assert.equal(harness.element('dashboard').hidden, true);
  assert.equal(harness.element('error-state').hidden, true);
  assert.equal(harness.fetchCalls.length, 1);
  assert.equal(harness.fetchCalls[0].url, '/api/stats');
  assert.equal(harness.fetchCalls[0].options.headers.Accept, 'application/json');
  assert.equal(harness.fetchCalls[0].options.method, undefined);
  assert.equal(harness.fetchCalls[0].options.cache, undefined);
  assert.deepEqual(
    harness.intervalRegistrations.map((registration) => registration.milliseconds),
    [60_000],
  );

  resolveFetch(responseWith(buildSnapshot()));
  await waitFor(
    () => harness.element('dashboard').hidden === false,
    'the populated dashboard',
  );

  const count = new Intl.NumberFormat(undefined, {maximumFractionDigits: 0});
  const average = new Intl.NumberFormat(undefined, {maximumFractionDigits: 1});
  assert.equal(harness.element('active-sessions').textContent, count.format(12));
  assert.equal(harness.element('support-open-lobbies').textContent, count.format(4));
  assert.equal(harness.element('matches-started').textContent, count.format(184));
  assert.equal(harness.element('matches-completed').textContent, count.format(131));
  assert.equal(harness.element('matches-abandoned').textContent, count.format(17));
  assert.equal(harness.element('average-turns').textContent, average.format(47.6));
  assert.equal(harness.element('longest-match').textContent, count.format(163));
  assert.equal(harness.element('total-turns').textContent, count.format(8421));
  assert.equal(harness.element('activity-heading').textContent, '30-day match activity');
  assert.equal(
    harness.element('last-updated').dateTime,
    '2026-07-12T10:00:00.000Z',
  );

  assert.equal(harness.element('activity-table-body').children.length, 30);
  assert.equal(harness.element('activity-table-body').children[0].children.length, 3);
  assert.equal(harness.element('turn-table-body').children.length, 5);
  assert.equal(harness.element('outcome-table-body').children.length, 6);
  assert.ok(harness.element('activity-chart').children.length > 2);
  assert.ok(harness.element('turn-chart').children.length > 2);
  assert.ok(harness.element('outcome-chart').children.length > 2);
  assert.equal(
    allText([harness.element('activity-chart')]).some((text) =>
      text.toLowerCase().includes('abandoned'),
    ),
    false,
    'Abandoned matches must not be charted as activity.',
  );
}

async function testEmptyContract() {
  const harness = new StatsHarness(async () => responseWith(buildSnapshot({empty: true})));
  harness.execute();
  await waitFor(
    () => harness.element('empty-state').hidden === false,
    'the empty state',
  );

  assert.equal(harness.element('dashboard').hidden, true);
  assert.equal(harness.element('loading-state').hidden, true);
  assert.equal(harness.element('error-state').hidden, true);
  assert.equal(harness.element('last-updated').dateTime, '2026-07-12T10:00:00.000Z');
}

async function testNetworkErrorAndRetry() {
  const responses = [
    () => Promise.reject(new TypeError('offline')),
    () => Promise.resolve(responseWith(buildSnapshot())),
  ];
  const harness = new StatsHarness(() => {
    const nextResponse = responses.shift();
    assert.ok(nextResponse, 'Unexpected additional stats request.');
    return nextResponse();
  });
  harness.execute();

  await waitFor(
    () => harness.element('error-state').hidden === false,
    'the network error state',
  );
  assert.match(harness.element('error-message').textContent, /could not be reached/i);
  assert.equal(harness.element('retry-button').disabled, false);

  harness.element('retry-button').click();
  await waitFor(
    () => harness.element('dashboard').hidden === false,
    'the dashboard after retry',
  );
  assert.equal(harness.fetchCalls.length, 2);
  assert.equal(harness.element('error-state').hidden, true);
}

async function testRequestTimeout() {
  const harness = new StatsHarness((_url, options) =>
    new Promise((_resolve, reject) => {
      options.signal.addEventListener(
        'abort',
        () => reject(new DOMException('Request timed out.', 'AbortError')),
        {once: true},
      );
    }),
  );
  harness.execute();
  harness.fireTimeout(10_000);

  await waitFor(
    () => harness.element('error-state').hidden === false,
    'the request-timeout error state',
  );
  assert.match(harness.element('error-message').textContent, /too long to respond/i);
  assert.equal(harness.element('retry-button').disabled, false);
}

async function testInvalidContract() {
  const invalidSnapshot = buildSnapshot();
  delete invalidSnapshot.turns;
  const harness = new StatsHarness(async () => responseWith(invalidSnapshot));
  harness.execute();
  await waitFor(
    () => harness.element('error-state').hidden === false,
    'the invalid-contract error state',
  );
  assert.match(harness.element('error-message').textContent, /could not be displayed/i);
}

async function testLabelsRemainText() {
  const maliciousTurnLabel = '<img src=x onerror=globalThis.__xss=true>';
  const maliciousOutcome = '<script>globalThis.__xss=true</script>';
  const snapshot = buildSnapshot();
  snapshot.turns.distribution.push({label: maliciousTurnLabel, count: 2});
  snapshot.outcomes.push({condition: maliciousOutcome, count: 1});

  const harness = new StatsHarness(async () => responseWith(snapshot));
  harness.execute();
  await waitFor(
    () => harness.element('dashboard').hidden === false,
    'the dashboard with additional labels',
  );

  const renderedText = allText(harness.createdElements);
  assert.ok(
    renderedText.includes(maliciousTurnLabel),
    'The turn label should be preserved as literal text in the fallback table.',
  );
  assert.ok(
    renderedText.some((text) => text.includes('<Script>GlobalThis')),
    'The additional outcome should be preserved as literal chart/table text.',
  );
  assert.equal(harness.htmlWrites.length, 0);
  assert.equal(harness.context.__xss, undefined);
  assert.equal(harness.element('turn-table-body').children.length, 6);
  assert.equal(harness.element('outcome-table-body').children.length, 7);
}

const watchdog = setTimeout(() => {
  console.error('Homepage stats DOM test exceeded its 10 second timeout.');
  process.exit(124);
}, 10_000);

try {
  await testPopulatedContractAndLoading();
  await testEmptyContract();
  await testNetworkErrorAndRetry();
  await testRequestTimeout();
  await testInvalidContract();
  await testLabelsRemainText();
  console.log(
    'Homepage stats DOM contract passed: populated, empty, retry, timeout, invalid, and safe-label states.',
  );
} finally {
  clearTimeout(watchdog);
}
