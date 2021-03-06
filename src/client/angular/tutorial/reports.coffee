guiders.createGuider
  title: "Reports"
  description: "The reports pages are for comparing your ads, campaigns, and apps against each other. We are constantly adding new features to this area."
  buttons: [{ name: "Next" }, { name: "Close" }]
  id: "reportsGuider1"
  next: "reportsGuider2"
  position: "6"
  overlay: true
  onClose: ->
    if window.UserService != undefined
      window.UserService.disableTutorial "reports"

guiders.createGuider
  title: "Report Timespan"
  description: "You can select a range for your data, and switch between normal and running-sum graphs."
  attachTo: ".contents.w920.center.campaign-reports-controls"
  buttons: [{ name: "What about funds?", onclick: guiders.navigate }, { name: "Previous" }, { name: "Close" }]
  id: "reportsGuider2"
  position: "6"
  overlay: true
  highlight: ".contents.w920.center.campaign-reports-controls"
  onNavigate: ->
    if window.UserService != undefined
      window.UserService.disableTutorial "reports", ->
        window.location.href = "/funds#guider=fundsGuider1"
    else
      window.location.href = "/funds#guider=fundsGuider1"
  onClose: ->
    if window.UserService != undefined
      window.UserService.disableTutorial "reports"
