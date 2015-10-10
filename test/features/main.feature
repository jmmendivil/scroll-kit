Feature: Visible elements

Scenario: First load (scrollTop: 0)

  Given loaded "/"
  Then should I see "0" within "#stats .keys"
  And should I see "0" within "#stats .scroll"
