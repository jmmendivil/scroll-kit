---
patterns:
  VERB: "(?:And|Then)"
---

Given loaded "$URI".

    (path) ->
      @browser
        .url('http://localhost:' + process.env.PORT + path)
        .waitForElementVisible('body', 1000)
        .resizeWindow(800, 600).pause(50)

When I stop for "$SECONDS".

    (seconds) ->
      @browser
        .pause(parseInt(seconds, 10) * 1000)

When I scroll to "$OFFSET_TOP".

    (offset_top) ->
      @browser
        .execute("scrollTo(0,#{offset_top})")
        .expect.element('#scroll-kit-info .scroll').text.to.equal(offset_top)

$VERB should I see "$TEXT" within "$SELECTOR".

    (text, selector) ->
      @browser
        .expect.element(selector).text.to.equal(text)
