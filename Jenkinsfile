#!/usr/bin/env groovy

REPOSITORY = 'rummager'

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'

  properties([
    buildDiscarder(
      logRotator(
        numToKeepStr: '50')
      ),
    [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false],
    [$class: 'ThrottleJobProperty',
      categories: [],
      limitOneJobWithMatchingParams: true,
      maxConcurrentPerNode: 1,
      maxConcurrentTotal: 0,
      paramsToUseForLimit: 'Rummager',
      throttleEnabled: true,
      throttleOption: 'category'],
  ])

  try {
    stage("Checkout") {
      checkout scm
    }

    stage("git merge") {
      govuk.mergeMasterBranch()
    }

    stage("bundle install") {
      govuk.bundleApp()
    }

    stage("rubylinter") {
      govuk.rubyLinter('app test lib')
    }

    stage("Run tests") {
      govuk.setEnvar('USE_SIMPLECOV', 'true')
      govuk.setEnvar('RACK_ENV', 'test')
      govuk.runRakeTask('ci:setup:minitest test --trace')
    }

    if (env.BRANCH_NAME == 'master') {
      stage("Push release tag") {
        govuk.pushTag(REPOSITORY, env.BRANCH_NAME, 'release_' + env.BUILD_NUMBER)
      }

      stage("Deploy to Integration") {
        govuk.deployIntegration(REPOSITORY, env.BRANCH_NAME, 'release', 'deploy')
      }

      stage("Publish JUnit test result report") {
        junit 'test/reports/*.xml'
      }

      stage("Publish Rcov report") {
        step([
          $class: 'RcovPublisher',
          reportDir: "coverage/rcov",
          targets: [
            [metric: "CODE_COVERAGE", healthy: 80, unhealthy: 0, unstable: 0]
          ]
        ])
      }
    }

  } catch (e) {
    currentBuild.result = "FAILED"
    step([$class: 'Mailer',
          notifyEveryUnstableBuild: true,
          recipients: 'govuk-ci-notifications@digital.cabinet-office.gov.uk',
          sendToIndividuals: true])
    throw e
  }

}
