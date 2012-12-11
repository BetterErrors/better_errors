module BetterErrors
  class System
    def self.sublime_available?
      return (`which subl` != "")
    end
  end
end