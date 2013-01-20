configure :production do
  if File.exist?("aws_secrets.yml")
    disable :show_exceptions
    use ExceptionMailer, YAML.load_file("aws_secrets.yml"),
        to: ['govuk-exceptions@digital.cabinet-office.gov.uk'],
        from: '"Winston Smith-Churchill" <winston@alphagov.co.uk>',
        subject: '[Rummager exception]'
  end
end