# frozen_string_literal: true

module HttpJsonHash
  class ServiceError < RuntimeError

    def initialize(path, args, name, body, message)
      @path = path
      @args = args
      @name = name
      @body = body
      super(message)
    end

    attr_reader :path, :args, :name, :body

    def ==(other)
      [path == other.path,
       args == other.args,
       name == other.name,
       body == other.body
     ].all?(true)
    end

  end
end
