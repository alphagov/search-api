#!/usr/bin/env groovy

library("govuk")

govuk.setEnvar("PUBLISHING_E2E_TESTS_APP_PARAM", "RUMMAGER_COMMITISH")

node('elasticsearch-6.7') {
  govuk.buildProject(
    publishingE2ETests: true,
    rubyLintDiff: false
  )
}
