#!/usr/bin/env groovy

node('elasticsearch-2.4') {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'
  govuk.buildProject()
}
