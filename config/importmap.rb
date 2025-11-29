# Pin npm packages by running ./bin/importmap

pin "application"

pin "@hotwired/turbo-rails", to: "turbo.min.js"

pin "@hotwired/stimulus", to: "stimulus.min.js"

pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin_all_from "app/javascript/controllers", under: "controllers"

pin "sortablejs" # @1.15.6

pin "@rails/request.js", to: "@rails--request.js.js" # @0.0.12



# Pin Chart.js directly to CDN to resolve dependency issues

pin "chart.js", to: "https://ga.jspm.io/npm:chart.js@4.4.0/dist/chart.js"

pin "chart.js/auto", to: "https://ga.jspm.io/npm:chart.js@4.4.0/auto/auto.js"

pin "@kurkle/color", to: "https://ga.jspm.io/npm:@kurkle/color@0.3.2/dist/color.esm.js"


pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
