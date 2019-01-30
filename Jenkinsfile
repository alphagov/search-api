#!/usr/bin/env groovy

library("govuk")

node('elasticsearch-5.6') {
  govuk.buildProject(publishingE2ETests: true)
}
