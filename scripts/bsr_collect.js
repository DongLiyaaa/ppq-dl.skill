(function () {
  var state = window.__PPQ_BSR_STATE || {
    expectedCount: 0,
    itemsByRank: {},
    passes: 0,
    lastCollectedCount: 0,
    lastMaxCollectedRank: 0,
    stableRounds: 0
  };

  var root = document.querySelector('.p13n-desktop-grid');
  var meta = [];
  try {
    meta = JSON.parse(root?.getAttribute('data-client-recs-list') || '[]');
  } catch (err) {}

  var rows = Array.from(document.querySelectorAll('.p13n-desktop-grid [id^="p13n-asin-index-"]'));
  var visibleItems = rows.map(function (row) {
    var wrapper = row.querySelector('[data-asin]');
    if (!wrapper) return null;
    var asin = wrapper.getAttribute('data-asin') || '';
    var rankText = row.querySelector('.zg-bdg-text')?.textContent?.trim() || '';
    var rank = parseInt((rankText.match(/\d+/) || ['0'])[0], 10) || null;
    var title =
      row.querySelector('img')?.getAttribute('alt')?.trim() ||
      row.querySelector('[class*="line-clamp"]')?.textContent?.trim() ||
      '';
    var rating = row.querySelector('.a-icon-row a[aria-label*="out of 5 stars"]')?.getAttribute('aria-label') || '';
    var reviews = row.querySelector('.a-icon-row .a-size-small')?.textContent?.trim() || '';
    var price =
      row.querySelector('.p13n-sc-price')?.textContent?.trim() ||
      row.querySelector('[class*="p13n-sc-price"]')?.textContent?.trim() ||
      '';
    return { rank: rank, asin: asin, title: title, rating: rating, reviews: reviews, price: price };
  }).filter(Boolean);

  visibleItems.forEach(function (item) {
    if (!item.rank) return;
    state.itemsByRank[String(item.rank)] = item;
  });

  var collected = Object.values(state.itemsByRank).sort(function (a, b) {
    return (a.rank || 9999) - (b.rank || 9999);
  });

  state.expectedCount = Math.max(state.expectedCount || 0, meta.length || 0);
  state.passes += 1;
  var maxCollectedRank = collected.length ? (collected[collected.length - 1].rank || 0) : 0;
  if (state.lastCollectedCount === collected.length && state.lastMaxCollectedRank === maxCollectedRank) {
    state.stableRounds += 1;
  } else {
    state.stableRounds = 0;
  }
  state.lastCollectedCount = collected.length;
  state.lastMaxCollectedRank = maxCollectedRank;
  var lastRow = rows[rows.length - 1] || null;
  if (lastRow && collected.length < (state.expectedCount || 0)) {
    lastRow.scrollIntoView({ block: 'end', inline: 'nearest', behavior: 'instant' });
    window.scrollBy(0, Math.max(Math.floor(window.innerHeight * 0.9), 600));
  }

  window.__PPQ_BSR_STATE = state;
  return JSON.stringify({
    pageUrl: location.href,
    expectedCount: state.expectedCount || 0,
    renderedCount: visibleItems.length,
    collectedCount: collected.length,
    minCollectedRank: collected.length ? collected[0].rank : null,
    maxCollectedRank: maxCollectedRank || null,
    stableRounds: state.stableRounds,
    passes: state.passes,
    isComplete: !!(state.expectedCount && collected.length >= state.expectedCount),
    shouldContinue: !!(state.expectedCount && collected.length < state.expectedCount),
    nextPageHref: document.querySelector('.a-pagination .a-last a')?.getAttribute('href') || ''
  });
})()
