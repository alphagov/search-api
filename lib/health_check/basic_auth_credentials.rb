module HealthCheck
  # A value class for basic auth credentials, with a user name and a password.
  # The `call` method is for compatibility with Slop's argument types.
  #
  # Because this is a Struct, the object can be passed into a Net::HTTP::Get
  # request's #basic_auth method with the splat operator.
  class BasicAuthCredentials < Struct.new(:user, :password)

    # Since we've got to provide a `call` method for Slop, let's make that the
    # only way to instantiate this class.
    private_class_method :new

    def self.call(value)
      error = "Credentials must be of the form 'user:password'"
      raise ArgumentError, error unless (value && value.include?(":"))
      new(*value.split(":", 2)).freeze
    end
  end
end
