(function () {
  var root = document.querySelector('.p13n-desktop-grid');
  var meta = [];
  try {
    meta = JSON.parse(root?.getAttribute('data-client-recs-list') || '[]');
  } catch (err) {}
  var cards = Array.from(document.querySelectorAll('.p13n-desktop-grid [id^="p13n-asin-index-"] [data-asin]'));
  return JSON.stringify({
    url: location.href,
    expectedCount: meta.length || 0,
    renderedCount: cards.length,
    isComplete: (meta.length || 0) > 0 && cards.length === meta.length,
    firstExpectedRank: meta[0]?.metadataMap?.['render.zg.rank'] || '',
    lastExpectedRank: meta.length ? meta[meta.length - 1].metadataMap?.['render.zg.rank'] || '' : '',
    nextPageHref: document.querySelector('.a-pagination .a-last a')?.getAttribute('href') || ''
  });
})()
