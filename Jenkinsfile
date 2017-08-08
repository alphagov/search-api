#!/usr/bin/env groovy

node('elasticsearch') {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'
  govuk.buildProject()
}
