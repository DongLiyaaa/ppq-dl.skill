(function () {
  var rows = Array.from(document.querySelectorAll('.p13n-desktop-grid [id^="p13n-asin-index-"]'));
  var items = rows.map(function (row) {
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

  items.sort(function (a, b) {
    return (a.rank || 9999) - (b.rank || 9999);
  });

  return JSON.stringify({
    pageUrl: location.href,
    count: items.length,
    firstRank: items[0]?.rank || null,
    lastRank: items.length ? items[items.length - 1].rank : null,
    items: items
  });
})()
