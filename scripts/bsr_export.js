(function () {
  var state = window.__PPQ_BSR_STATE || { expectedCount: 0, itemsByRank: {} };
  var items = Object.values(state.itemsByRank || {}).sort(function (a, b) {
    return (a.rank || 9999) - (b.rank || 9999);
  });
  return JSON.stringify({
    expectedCount: state.expectedCount || 0,
    count: items.length,
    firstRank: items.length ? items[0].rank : null,
    lastRank: items.length ? items[items.length - 1].rank : null,
    isComplete: !!(state.expectedCount && items.length >= state.expectedCount),
    items: items
  });
})()
