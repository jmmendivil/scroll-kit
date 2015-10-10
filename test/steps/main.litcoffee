---
patterns:
  VERB: "(?:And|Then)"
---

Given loaded "$URI".

    (path) ->
      @browser
        .url('http://localhost:' + process.env.PORT + path)
        .waitForElementVisible('body', 1000)

$VERB should I see "$TEXT" within "$SELECTOR".

    (text, selector) ->
      @browser
        .expect.element(selector).text.to.contain(text)
