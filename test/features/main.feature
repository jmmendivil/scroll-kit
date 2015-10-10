Feature: Visible elements

Scenario: First load

  Given loaded "/"
  When I scroll to "0"
  Then should I see "0" within "#stats .keys"

Scenario: Scrolling a bit

  Given loaded "/"
  When I scroll to "1000"
  Then should I see "0, 1" within "#stats .keys"
