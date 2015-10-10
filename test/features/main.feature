Feature: Visible elements

Scenario: First load

  Given loaded "/"
  When I scroll to "0"
  Then should I see "0" within "#stats .keys"
  And should I see "initial / static" within "#stats .from_to"

Scenario: Scrolling a bit

  Given loaded "/"
  When I scroll to "1000"
  Then should I see "0, 1" within "#stats .keys"
  And should I see "static / forward" within "#stats .from_to"

  When I scroll to "0"
  And should I see "forward / backward" within "#stats .from_to"

  When I stop for "1s"
  Then should I see "backward / static" within "#stats .from_to"

Scenario: Scrolling so far

  Given loaded "/"
  When I scroll to "4000"
  Then should I see "7, 8" within "#stats .keys"
  And should I see "static / forward" within "#stats .from_to"
