module BetterErrors
  # @private
  module REPL
    PROVIDERS = [
        { impl:   "better_errors/repl/basic",
          const:  :Basic },
      ]

    def self.provider
      @provider ||= const_get detect[:const]
    end
    
    def self.provider=(prov)
      @provider = prov
    end
    
    def self.detect
      PROVIDERS.find do |prov|
        test_provider prov
      end
    end
    
    def self.test_provider(provider)
      require provider[:impl]
      true
    rescue LoadError
      false
    end
  end
end
