require "sassc"

module BetterErrors
  # @private
  module ErrorPageStyle
    def self.compiled_style(for_deployment = false)
      style_dir = File.expand_path("style", File.dirname(__FILE__))
      style_file = "#{style_dir}/main.scss"

      engine = SassC::Engine.new(
        File.read(style_file),
        filename: style_file,
        style: for_deployment ? :compressed : :expanded,
        line_comments: !for_deployment,
        load_paths: [style_dir],
      )
      engine.render
    end

    def self.style_tag
      style_file = File.expand_path("templates/main.css", File.dirname(__FILE__))
      css = if File.exist?(style_file)
        File.open(style_file).read
      else
        compiled_style(false)
      end
      "<style type='text/css'>\n#{css}\n</style>"
    end
  end
end
