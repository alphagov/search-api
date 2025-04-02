module GovukIndex
  class MissingTextHtmlContentType < StandardError; end

  class NotFoundError < StandardError; end

  class UnknownDocumentTypeError < StandardError; end

  class NotIdentifiable < StandardError; end
end
